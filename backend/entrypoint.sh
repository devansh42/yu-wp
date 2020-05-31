#!/bin/bash
# This script starts Api Server with gunicorn
# For Backend Directory creation
mkdir -p /var/log/backend /var/wp
gunicorn -b 0.0.0.0:80 -w 4 run:app