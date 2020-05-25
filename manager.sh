#!/usr/bin/bash
# Script to export environment variables

function setenv() {
    # sets environmental variables
    awk -F = '{printf "export %s=%s",$1,$2 }' manager.env >> ~/.bashrc

}

setenv