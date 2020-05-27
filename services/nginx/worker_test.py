#!/usr/bin/python3
import unittest
import redis
import os
from .worker import init, handle_new_site, handle_certs


class TestWorker(unittest.TestCase):
    def setUp(self):
        # Doing some inital setup
        os.environ["REDIS_HOST"] = 1
        os.environ["SSL_DIR"] = 1
        os.environ["NODEID"] = 1
        self.r = redis.Redis(host=os.getenv("REDIS_HOST"))
    # Tests new site handling

    def test_handle_new_site_beg(self):
        d = {
            "name": "demo.tld",
            "oid": 1,
            "domains": "demo.tld www.demo.tld",
            "plan": "beg"
        }
        # Testing for beginner

        handle_new_site(d)

    def test_handle_new_site_adv(self):
        d = {
            "name": "demo1.tld",
            "oid": 2,
            "domains": "demo1.tld www.demo1.tld", "plan": "beg"
        }
        # Testing for advance
        handle_new_site(d)

    def test_handle_certs(self):
        d = {
            "domains": "demo.tld www.demo.tld",
            "oid": 1
        }
        handle_certs(d)


if __name__ == "__main__":
    unittest.main()
