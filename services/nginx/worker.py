#!/usr/bin/python3
# This scripts manages underlying orders for certificate requests n all

import redis
import os
import json
import subprocess
REDIS_HOST = os.getenv("REDIS_HOST")
SSL_DIR = os.getenv("SSL_DIR")
NODEID = os.getenv("NODEID")


def init():
    r = redis.Redis(host=REDIS_HOST)
    ps = r.pubsub(ignore_subscribe_messages=True)
    ps.subscribe("n%s-yu-wp-certificates" %
                 NODEID, "n%s-yu-wp-new-site" % NODEID)
    for msg in ps.listen():
        ch = msg["channel"].decode("utf8")
        data = json.loads(msg["data"].decode("utf8"))
        if ch == "n%s-yu-wp-certificates" % NODEID:
            handle_certs(data)
        else:
            handle_new_site(data)


"""
Handles certificate requests
"""


def handle_certs(data: dict):
    domains: [str] = data["domains"]
    order: int = data["oid"]
    with open("%s/issue%d" % (SSL_DIR, order), "w") as w:
        w.writelines(domains)
    # Adding new certificate request


"""
Handles New Site Request
"""


def handle_new_site(data: dict):
    name = data["domain"]
    oid = data["oid"]
    domains = data["domains"]
    plan = data["plan"]
    subprocess.run("%s/docker.sh %s %s %s '%s'" %
                   (os.path.dirname(__file__),oid, plan, name, domains))


if __name__ == "__main__":
    init()
