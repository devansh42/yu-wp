#!/bin/bash
# Script to export environment variables

function setenv() {
    # sets environmental variables
    awk -F = '{printf "\nexport %s=%s",$1,$2 }' manager.env >>~/.bashrc

}

function network() {
    #creates overlay network
    docker network ls | grep wp_overlay ||
        docker network create --driver overlay --attachable wp_overlay
}

setenv

network
