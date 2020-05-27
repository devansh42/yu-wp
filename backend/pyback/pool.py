"""
This module contain apis for backend resource management
"""
import docker


"""
Returns default docker client
"""

def get_docker_client():
    return docker.from_env()


"""
Retrives worker nodes in docker swarm
"""


def get_node_list():
    d = get_docker_client()
    l: [docker.models.nodes.Node] = d.nodes.list(filter={"role": "worker"})
    return list(map(lambda x: x.id, l))

"""
Choosen node
"""
choosen_node = 0

"""
Returns next node to load using round robin technique
"""


def get_next_node() -> str :
    global choosen_node
    l: [str] = get_node_list()
    n = l[choosen_node]
    if choosen_node == len(l)-1:
        choosen_node = 0
    return n
