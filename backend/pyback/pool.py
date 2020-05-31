"""
This module contain apis for backend resource management
"""
import os


class Node:
    def __init__(self, id: str, hostname: str, domain: str):
        self.id, self.hostname, self.domain = id, hostname, domain


# File that contains code info of nodes
NODESFILE = os.getenv("NODESFILE")

"""
-- Structure of NODESFILE -- 
NODEID HOSTNAME DOMAIN
"""


"""
Retrives nodes from nodefile
"""


def get_node_list():

    with open(NODESFILE, "r") as f:
        return [Node(x[0], x[1], x[2]) for x in line.split() for line in f.readlines()]



"""
Choosen node
"""
choosen_node = 0

"""
Returns next node to load using round robin technique
"""


def get_next_node() -> Node:
    global choosen_node
    l: [Node] = get_node_list()
    n = l[choosen_node]
    if choosen_node == len(l)-1:
        choosen_node = 0
    return n
