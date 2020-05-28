#!/bin/bash
docker build -t 10.139.128.30:5210/yu-wp-nginx .
docker push 10.139.128.30:5210/yu-wp-nginx
