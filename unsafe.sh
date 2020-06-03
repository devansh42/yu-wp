#!/bin/bash
if ! [ -f '/etc/docker/daemon.json' ]; then
    cat >/etc/docker/daemon.json <<EOF
{
    "insecure-registries":["$DOCKER_REG"]
}
EOF
    echo "Resatrting Docker ..."
    service docker restart
    echo "Docker Restarted"
fi
