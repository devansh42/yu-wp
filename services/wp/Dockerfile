FROM wordpress:php7.4-fpm-alpine 
RUN apk update && apk add bash 
ADD . .
# For sharebale mount point
RUN mkdir -p /wp/link 
ENTRYPOINT ["bash","entrypoint.sh"]