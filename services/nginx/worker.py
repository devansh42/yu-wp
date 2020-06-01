#!/usr/bin/python3
# This scripts manages underlying orders for certificate requests n all

import redis
import os
from string import Template
import tempfile
import json
import time
import subprocess
import docker
import asyncio
import logging
from hashlib import sha1


ORDER_SITE = "site"
ORDER_SSL = "ssl"


REDIS_HOST = os.getenv("REDIS_HOST")
DNODEID = os.getenv("DNODEID")
DOCKER_REG = os.getenv("DOCKER_REG")
BACKUP_SITE_FILE = os.getenv("BACKUP_SITE_FILE")
NGINX_CONF = os.getenv("NGINX_CONF")
EMAIL = os.getenv("EMAIL")
NODEID = os.getenv("NODEID")  # Will  be the hostname of host
# Channel for response forwarding
RESPONSECH = "res-yu-wp"
# Logging initalizer
logging.basicConfig(filename="/var/log/wp/site/docker.log", filemode="a+")


def init():
    loop = asyncio.get_event_loop()
    r = redis.Redis(host=REDIS_HOST)
    ps = r.pubsub(ignore_subscribe_messages=True)
    ps.subscribe("n%s-yu-wp-certificates" %
                 NODEID, "n%s-yu-wp-new-site" % NODEID)
    for msg in ps.listen():

        ch = msg["channel"].decode("utf8")
        data = json.loads(msg["data"].decode("utf8"))
        if ch == "n%s-yu-wp-certificates" % NODEID:
            # Running things concurrently
            loop.create_task(handle_certs(data, redis=r, loop=loop))

        else:
            loop.create_task(handle_new_site(data, redis=r, loop=loop))

    loop.run_forever()


"""
Handles certificate requests
Logs error /var/log/wp/ssl/error.log
Logs Output /var/log/wp/ssl/log.log
"""


async def handle_certs(data: dict, redis, loop):
    domains: str = data["domains"]
    order: int = data["oid"]
    d = []
    for x in domains.split():
        if len(x.strip()) > 0:
            d.append(x.strip())
    ds: str = " -d ".join(d)
    o = open("/var/log/wp/ssl/log.log", "a+")
    e = open("/var/log/wp/ssl/error.log", "a+")
    t = loop.create_task(
        req_cert("certbot --agree-tos -n -m %s --nginx %s" % (EMAIL, ds), o, e))

    resp = dict()
    resp["oid"] = order,
    resp["type"] = ORDER_SSL
    resp["status"] = 1  # Requesting Certificate
    redis.publish(RESPONSECH, json.dumps(resp))
    st = await t
    o.close()
    e.close()

    if st.returncode == 0:
        # Certification provisioned successfully
        resp["status"] = 2

    else:
        resp["status"] = 3
        # Couldn't Provisioned Certificate
    redis.publish(RESPONSECH, json.dumps(resp))


async def req_cert(cmd, o, e):
    return subprocess.run(cmd.split(), stdout=o, stderr=e)

"""
Handles New Site Request
Output Log : /var/log/wp/site/log.log
Error Log : /var/log/wp/site/error.log
"""


async def handle_new_site(data: dict, redis, loop):
    name = data["domain"]
    oid = data["oid"]
    domains = data["domains"]
    temp_domain = data["temp_domain"]
    plan = data["plan"]
    wp = data["wordpress"]
    with tempfile.TemporaryDirectory() as dirname:
        s = ""
        with open("%s/wp.yml" % os.path.dirname(__file__)) as f:
            t = Template(f.read())
            s = t.substitute(
                {"DOCKER_REG": DOCKER_REG, "OID": oid, "NODEID": DNODEID})
        with open("%s/wp.yml" % dirname, "w") as f:
            f.write(s)
        with open("%s/env.env" % dirname, "w") as f:
            f.writelines(make_env_file(wp))
        o = open("/var/log/wp/site/log.log", "a+")
        e = open("/var/log/wp/site/error.log", "a+")
        resp = {
            "type": "site",
            "oid": oid,
            "status": 2
        }
        r = subprocess.run("docker stack up -c %s/wp.yml" %
                           dirname, stdout=o, stderr=e)  # Deploying Docker container
        o.close()
        e.close()
        if r.returncode != 0:
            # dede
            redis.publish(RESPONSECH, json.dumps(resp))

        else:
            if plan == "adv":
                enable_backup(oid)

            try:
                setup_conf(oid, temp_domain, name, domains)
                subprocess.run("nginx -s reload")
                resp["status"] = 1
                redis.publish(RESPONSECH, json.dumps(resp))
            except Exception as err:
                redis.publish(RESPONSECH, json.dumps(resp))
                logging.error(err)
"""
enable_backup, Enable backup for site
"""


def enable_backup(oid: str):
    with open(BACKUP_SITE_FILE, "a") as f:
        f.writelines([oid])


"""
setup_conf, Setup configuration for nginx
"""


def setup_conf(oid: str, temp_domain: str, name: str, domains: str):
    d = docker.from_env()
    cs: [docker.models.containers.Container] = d.containers(
        filter="label=oid=%s" % oid)
    port = 0
    for c in cs:
        for p in c.ports.keys():
            if c.ports[p] == "80":
                port = p
                break
    with open("%s/nginx.conf" % os.path.dirname(__file__), "r") as f:
        t = Template(f.read())
        ts = t.substitute({"oid": oid, "temp_name": temp_domain, "server_names": domains,
                           "bind_addr": "wp_%s:%s" % (oid, port)})
        g = (NGINX_CONF, name)

        with open("%s/sites-available/%s.conf" % g) as f:
            f.write(ts)
        os.symlink("%s/sites-available/%s.conf" % g, "%s/conf.d/%s.conf" % g)


"""
make_env_file, makes env file
"""


def make_env_file(d: dict):
    ar = []
    for k in d.keys():
        ar.append("%s=%s" % (k, d[k]))
    return ar


if __name__ == "__main__":
    init()
