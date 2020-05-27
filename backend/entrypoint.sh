#!/bin/bash
# This script starts Api Server with gunicorn

gunicorn -b 0.0.0.0:80 -w 4 run:app