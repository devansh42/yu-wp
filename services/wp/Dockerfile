FROM wordpress:php7.4-fpm-alpine 
RUN apk update && apk add bash 
RUN mkdir -p /wp/link 
ENTRYPOINT ["bash","entrypoint.sh > /tmp/log.log"]
COPY entrypoint.sh entrypoint.sh
USER www-data
# For sharebale mount point
