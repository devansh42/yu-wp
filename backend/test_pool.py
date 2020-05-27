#!/usr/bin/python3
from .pool import get_docker_client, get_node_list, get_next_node
import unittest


class TestPoolMethods(unittest.TestCase):
    def test_get_docker_client(self):
        d = get_docker_client()
        self.assertIsNotNone(d.version)

    def test_get_node_list(self):
        l: [str] = get_node_list()
        self.assertTrue(len(l) > 0)

    def test_get_next_node(self):
        l: [str] = get_node_list()
        c: [str] = []
        for x in range(len(l)):
            n = get_next_node()
            c.append(n)
        # It also checks for sequence
        self.assertListEqual(l, c)


if __name__ == "__main__":
    unittest.main()
