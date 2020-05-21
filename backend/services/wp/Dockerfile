FROM wordpress:php7.4-fpm-alpine 
RUN apk update && apk add bash 
ADD . .
CMD ["bash entrypoint.sh","&&","php-fpm"]