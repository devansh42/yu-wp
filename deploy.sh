#!/bin/bash
# This scripts deploy any of the services avialable in this project

#Deploys project in stack mode
# $1 => Compose File
# $2 => stack_name


stack() {
    docker stack up -c $1 $2
}

dcompose() {
    docker-compose -f $1 up -d
}

if [ $# -lt "1" ]; then
    echo "Please specify deploy target"
    exit 1
fi

for x in $(seq $#); do
    case $1 in
    db | redis | backend | nginx)
        stack compose/$1.yml stack_$1
        ;;
    *)
        echo "No deployment  configuration found"
        echo "Potential targets are"
        echo "db redis backend nginx"
        ;;
    esac
    shift 1
done
