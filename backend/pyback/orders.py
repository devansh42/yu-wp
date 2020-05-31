"""
This is module manages orders by users
"""
import os
import subprocess
import redis
import json
import random
import hashlib
from hashlib import sha1
from time import time
import mysql.connector as connector
from .pool import get_next_node
from .secrets import get_default_mysql_conn, get_default_redis_conn
import digitalocean
# This imported because is will the mysql host address for wordpress instances
from .secrets import MYSQL_HOST
BEGINNER_PACK_ID = 1
ADVANCE_PACK_ID = 2

DOMAINSUFFIX = os.getenv("DOMAINSUFFIX")
DOTOKEN = os.getenv("DOTOKEN")
ORDER_SITE = "site"
ORDER_SSL = "ssl"
RESPONSECH = "res-yu-wp"


"""
process's an incomming order
@param order : This is the woocommerce order detail object
"""


def process_order(order: dict):
    site_domain = ""
    with get_default_mysql_conn() as conn:
        cur = conn.cursor()
        id: str = order["id"]
        db_name = "yu_wp_user_data_"+id
        username = "u"+id
        passwd = get_random_password(id)
        ar = []
        sql = "create user %s@%s identified by %s"
        val = (username, "%", passwd)
        ar += [(sql, val)]
        sql = "create database %s"
        val = (db_name)
        ar += [(sql, val)]
        sql = "grant all PRIVILEGES on %s.* to %s@%s"
        val = (db_name, username, "%")
        ar += (sql, val)
        for (s, v) in ar:
            cur.execute(s, v)

        data: dict = {
            "WORDPRESS_DB_USER": username,
            "WORDPRESS_DB_PASSWORD": passwd,
            "WORDPRESS_DB_NAME": db_name,
            "WORDPRESS_DB_HOST": MYSQL_HOST,
            "WORDPRESS_AUTH_KEY": get_random_sk(),
            "WORDPRESS_SECURE_AUTH_KEY": get_random_sk(),
            "WORDPRESS_LOGGED_IN_KEY": get_random_sk(),
            "WORDPRESS_NONCE_KEY": get_random_sk(),
            "WORDPRESS_AUTH_SALT": get_random_sk(),
            "WORDPRESS_SECURE_AUTH_SALT": get_random_sk(),
            "WORDPRESS_LOGGED_IN_SALT": get_random_sk(),
            "WORDPRESS_NONCE_SALT": get_random_sk(),
            "OID": id
        }
        with get_default_redis_conn() as r:
            for item in order["line_items"]:
                metas = item["meta_data"]
                meta_data = dict()
                for x in metas:  # Populating meta_data dictionary
                    meta_data[x["key"]] = x["value"]
                node = get_next_node()
                nid = node.hostname
                data["NODEID"] = nid
                site_domain = node.domain
                plan = "beg" if item["id"] == BEGINNER_PACK_ID else "adv"
                domain = meta_data["domain"]
                domains = meta_data["domains"]
                td = get_temp_domain(id)
                set_domain_cname(td, node.domain) # Domain Pairing
                pd = json.dumps({
                    "temp_domain": td,
                    "domain": domain,
                    "domains": domains,  # Space seperated domains
                    "plan": plan,
                    "oid": id,  # Order Id
                    "wordpress": data  # Environment Variables
                })
                r.publish("n%s-yu-wp-new-site" % nid, pd)
                sql = "insert into orders(oid,temp_domain,ssl_status,otype,domain,domains)values(%s,%d,%s,%s,%s)"
                val = (id, td, 0, plan, domain, domains)
                cur.execute(sql, val)
        cur.commit()  # Commiting database

    return site_domain


"""
process_ssl, process new ssl request for users
This function doesn't need to be tested as it is straight forward

"""


def process_ssl(order: dict):
    with get_default_mysql_conn() as conn:
        cursor = conn.cursor()
        oid = order["id"]
        sql = "update orders set ssl_status=%s where oid=%d"
        val = (1, oid)
        cursor.execute(sql, val)
        sql = "select nid,domain,domains from orders where oid=%d limit 1"
        val = (oid)
        cursor.execute(sql, val)
        res = cursor.fetchall()
        d = dict()
        for x in res:
            d = {
                "nid": x["nid"],
                "domains": x["domains"],
                "domain": x["domain"]
            }
            break
        with get_default_redis_conn() as red:
            red.publish("n%s-yu-wp-certificates" % d["nid"], json.dumps(d))
        cursor.commit()


"""
Checks for ssl status,
This function doesn't need to be tested as it is straight forward
"""


def check_ssl_status(order: dict):
    return __check_status__(order, "ssl")


def check_site_status(order: dict):
    return __check_status__(order, "site")


def __check_status__(order: dict, item: str):
    id = order["id"]
    with get_default_mysql_conn() as conn:
        c = conn.cursor()
        sql = ""
        sql = "select site_status from orders where oid=%s limit 1" if item == "site" else "select ssl_status from orders where oid=%s limit 1"
        val = (id)
        c.execute(sql, val)
        for x in c.fetchall():
            return x["ssl_status" if item == "ssl" else "site_status"]


def get_random_password(oid: str) -> str:
    m = hashlib.sha256()
    m.update(b"%s%d" % (oid, time()))
    return m.hexdigest()


"""
get_random_sk returns random salt and key
"""


def get_random_sk() -> str:
    m = hashlib.sha256()
    m.update(b"%s%d" % (random.random(), time()))
    return m.hexdigest()


def make_env_file(data: dict) -> [str]:
    return ["%s=%s" % (x, data[x]) for x in data.keys()]


# The Puspose of this method is to change db state as required
async def response_handler():
    with get_default_mysql_conn() as conn:
        c = conn.cursor()

        with get_default_redis_conn() as r:
            ps = r.pubsub(ignore_subscribe_messages=True)
            ps.subscribe(RESPONSECH)
            for data in ps.listen():
                d = json.loads(data["data"].decode("utf-8"))
                sql = ""
                if d["type"] == ORDER_SSL:
                    sql = "update orders set ssl_status = %s where oid = %s limit 1"
                elif d["type"] == ORDER_SITE:
                    sql = "update orders set site_status = %s where oid = %s limit 1"
                c.execute(sql, (d["status"], d["oid"]))
                c.commit()  # Commiting transaction


def get_temp_domain(oid: str):
    p = int(sha1(b"%s%s" % (oid, time())).hexdigest(), 16) % (10**6)
    return "%d.%s" % (p, DOMAINSUFFIX)


def set_domain_cname(td: str, domain: str):
    d = digitalocean.Domain(token=DOTOKEN, name=DOMAINSUFFIX)
    d.create_new_domain_record(
        type="CNAME", name=td.split(".")[0], data=domain)
