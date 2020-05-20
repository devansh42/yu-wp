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
from .secrets import MYSQL_PASSWD, MYSQL_HOST, DEPLOYMENT_DIR, REDIS_HOST

BEGINNER_PACK_ID = 1
ADVANCE_PACK_ID = 2



"""
process's an incomming order
@param order : This is the woocommerce order detail object
"""


def process_order(order: dict):
    with connector.connect(host=MYSQL_HOST, user="root", passwd=MYSQL_PASSWD, database="yu_wp_data") as conn:
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
        cur.commit()
        data: dict = {
            "DB_USER": username,
            "DB_PASSWD": passwd,
            "DB_NAME": db_name,
            "DB_HOST": MYSQL_HOST
        }
        with redis.Redis(host=REDIS_HOST) as r:
            for item in order["line_items"]:

                nid = get_next_node()
                data["NODEID"] = nid
                dd = "%s/%s" % (DEPLOYMENT_DIR, id)
                os.mkdir(dd)
                with open("%s/env.env" % dd, "w") as w:
                    w.writelines(make_env_file(data))

                com = subprocess.run(
                    "bash ./backend/services/wp/deploy.sh %s %s" % (dd, "beg" if item["id"] == BEGINNER_PACK_ID else "adv"))
                pd = json.dumps({
                    "site-name": item["site-name"]
                    # Some other details
                })
                r.publish("yu-wp-new-site-%s" % nid,pd)


def get_random_password(oid:str) -> str:
    m=hashlib.sha256()
    m.update(b"%s%d"%(oid,time()))
    return m.hexdigest()


def make_env_file(data: dict):
    return ["%s=%s" % (x, data[x]) for x in data.keys()]
