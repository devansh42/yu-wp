#!/bin/bash
# This scripts build any of the services avialable in this project
# This takes $1 as build Target


build() {
    docker build -t $DOCKER_REG/$1 $2
    docker push $DOCKER_REG/$1
}

if [ $# -lt "1" ]; then
    echo "Please specify build target"
    exit 1
fi

for x in $(seq $#); do
    case $1 in
    nginx | ssl | conf | wp)
        build yu_wp:$1 services/$1
        ;;
    db | backend)
        build yu_wp:$1 $1
        ;;
    *)
        echo "No Build Config found for given project"
        echo "Available options are, "
        echo "nginx ssl conf db backend wp"
        ;;
    esac
    shift 1
done
