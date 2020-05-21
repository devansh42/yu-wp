"""
This is module manages orders by users
"""
import os
import subprocess
import redis
import json
import hashlib
from time import time
import mysql.connector as connector
from .pool import get_next_node
from .secrets import MYSQL_PASSWD, MYSQL_HOST, DEPLOYMENT_DIR, REDIS_HOST, get_default_mysql_conn, get_default_redis_conn

BEGINNER_PACK_ID = 1
ADVANCE_PACK_ID = 2


"""
process's an incomming order
@param order : This is the woocommerce order detail object
"""


def process_order(order: dict):
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
            "DB_USER": username,
            "DB_PASSWD": passwd,
            "DB_NAME": db_name,
            "DB_HOST": MYSQL_HOST
        }
        with get_default_redis_conn() as r:
            for item in order["line_items"]:
                metas = item["meta_data"]
                meta_data = dict()
                for x in metas:  # Populating meta_data dictionary
                    meta_data[x["key"]] = x["value"]
                nid = get_next_node()
                data["NODEID"] = nid
                dd = "%s/%s" % (DEPLOYMENT_DIR, id)
                os.mkdir(dd)
                with open("%s/env.env" % dd, "w") as w:
                    w.writelines(make_env_file(data))
                plan = "beg" if item["id"] == BEGINNER_PACK_ID else "adv"
                com = subprocess.run(  # Running backend script
                    "bash %s/services/wp/deploy.sh %s %s" % (os.path.dirname(__file__), dd, plan))
                domain = meta_data["domain"]
                domains = meta_data["domains"]
                pd = json.dumps({
                    "domain": domain,
                    "domains": domains,  # Space seperated domains
                    "plan": plan,
                    "oid": id  # Order Id
                })
                r.publish("n%s-yu-wp-new-site" % nid, pd)
                sql = "insert into orders(oid,ssl_status,otype,domain,domains)values(%s,%d,%s,%s,%s)"
                val = (id, 0, plan, domain, domains)
                cur.execute(sql, val)
        cur.commit()  # Commiting database


"""
Processes SSL Request
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
Checks for ssl status
"""


def check_ssl_status(order: dict):
    id = order["id"]
    with get_default_mysql_conn() as conn:
        cursor = conn.cursor()
        sql = "select ssl_status from orders where oid=%s limit 1"
        val = (id)
        cursor.execute(sql, val)
        for x in cursor.fetchall():
            return x["ssl_status"]


def get_random_password(oid: str) -> str:
    m = hashlib.sha256()
    m.update(b"%s%d" % (oid, time()))
    return m.hexdigest()


def make_env_file(data: dict):
    return ["%s=%s" % (x, data[x]) for x in data.keys()]
