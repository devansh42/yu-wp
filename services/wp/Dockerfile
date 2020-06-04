FROM wordpress:php7.4-fpm-alpine 
RUN apk update && apk add bash 

ENTRYPOINT ["bash","entrypoint.sh"]
WORKDIR /wp
COPY  entrypoint.sh entrypoint.sh

# For sharebale mount point
