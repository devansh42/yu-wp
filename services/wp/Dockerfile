FROM wordpress:php7.4-fpm-alpine 
RUN apk update && apk add bash 
RUN mkdir -p /wp/link 
ENTRYPOINT ["bash","entrypoint.sh"]
COPY entrypoint.sh entrypoint.sh
# For sharebale mount point
