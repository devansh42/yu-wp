#!/bin/bash
# Script to manage mangers

function network() {
    #creates overlay network
    docker network ls | grep wp_overlay ||
        docker network create --driver overlay --attachable wp_overlay
}

function registry(){

    #creates registry if not exists
   docker ps | grep registry > /dev/null ||  docker run -d -p 5210:5000 registry:2

}
registry
network
