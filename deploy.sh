#!/bin/bash
# This scripts deploy any of the services avialable in this project

#Deploys project in stack mode
# $1 => Compose File
# $2 => stack_name

stack() {
    docker stack up -c $1 $2
}

# db() {
#     stack compose/db.yml stack_db
# }

# redis() {
#     stack compose/redis.yml stack_redis
# }
# backend() {
#     stack compose/backend.yml stack_backend
# }
# nginx() {
#     stack compose/nginx.yml stack_nginx
# }
case $1 in
db | redis | backend | nginx)
    stack compose/$1.yml stack_$1
    ;;
*)
    echo "No deployment  configuration found"
    ;;
esac
