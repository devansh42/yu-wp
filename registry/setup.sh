#!/bin/bash
# This scripts sets up docker registry for different container usage
docker run -d -p 5210:5000 registry:2
echo "Registry has been setup"
