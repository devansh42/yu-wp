#!/usr/bin/python3
import os
import unittest
from .secrets import get_default_mysql_conn
from .orders import process_order, process_ssl, get_random_password, make_env_file


class TestOrders(unittest.TestCase):
    def setUp(self):
        os.environ["MYSQL_HOST"] = ""

    def test_get_random_password(self):
        passwd = get_random_password("12")
        print(len(passwd), passwd)

    def test_make_env_file(self):
        d = {
            "a": "1",
            "b": "2",
            "c": "3"
        }
        x = make_env_file(d)
        self.assertListEqual(x, ["a=1", "b=2", "c=3"])

    def test_process_order(self):
        d = {
            "id": "19856562",
            "line_items": [
                {"id": 1,  # Begginer Pack
                 "meta_data": [
                     {"key": "domain", "value": "domain.tld"},
                     {"key": "domains", "value": "domain.tld www.domain.tld"}
                 ]}
            ]

        }
        process_order(d)
        d1 = {
            "id": "19856563",
            "line_items": [
                {"id": 2,  # Begginer Pack
                 "meta_data": [
                     {"key": "domain", "value": "domain1.tld"},
                     {"key": "domains", "value": "domain1.tld www.domain1.tld"}
                 ]}
            ]

        }
        process_order(d1)

    def test_process_ssl(self):
        with get_default_mysql_conn() as db:
            id = "198565690"
            c = db.cursor()
            # Inserting records
            s = "insert into orders(oid,nid,domain,domains,ssl_status)values(%d,%s,%s,%s,%d)"
            v = (id, "n1", "domain.tld",
                 "domain.tld www.domain.tld", 0)
            c.execute(s, v)
            c.commit()
            d = {
                "id": id
            }
            process_ssl(d)
            s = "delete from orders where oid=%s limit 1"
            v = (id)
            c.execute(s, v)
            c.commit()


if __name__ == "__main__":
    unittest.main()
