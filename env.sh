#!/bin/bash
nodeid=$(hostname)
dnodeid=$(docker info | grep NodeID | awk -F : '{print $2}')
read -p "Enter Docker repo Addr " docker_reg
if [ -z "$DOCKER_REG" ]; then
    echo 'export DOCKER_REG=$docker_reg' >>~/.bashrc
    echo "Docker Reg Set"
fi
if [ -z "$DNODEID" ]; then
    echo 'export DNODEID=$dnodeid' >>~/.bashrc
    echo "Docker Node Id Set"
fi
if [ -z "$NODEID" ]; then
    echo 'export NODEID=$nodeid' >>~/.bashrc
    echo "NodeId set"
fi
