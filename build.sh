#!/bin/bash
# This scripts build any of the services avialable in this project
# This takes $1 as build Target

DOCKER_REG=10.139.128.30:5210

build() {
    docker build -t $DOCKER_REG/$1 $2
    docker push $DOCKER_REG/$1
}

# db() {
#     build yu_wp:db db
# }
# backend() {
#     build yu_wp:backend backend
# }
# wp() {
#     build yu_wp:wp backend/pyback/services/wp
# }
# nginx() {
#     build yu_wp:nginx services/nginx
# }
# ssl() {
#     build yu_wp:ssl services/ssl
# }
# conf() {
#     build yu_wp:conf services/server
# }

if [ $# -lt "1" ]; then
    echo "Please specify build target"
    exit 1
fi

case $1 in
nginx | ssl | conf)
    build yu_wp:$1 services/$1
    ;;
db | backend)
    build yu_wp:$1 $1
    ;;
wp)
    build yu_wp:$1 backend/pyback/services/$1
    ;;
*)
    echo "No Build Config found for given project"
    ;;
esac
