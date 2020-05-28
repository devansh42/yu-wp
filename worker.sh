#!/bin/bash

# Script to manage Workers
set_wps_volume() {
    docker volume ls | grep wps_data || docker volume create wps_data
}

set_wps_volume # Setting up WordPress Volume
