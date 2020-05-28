FROM alpine
RUN apk update && apk add certbot bash certbot-nginx
ADD . .
ENTRYPOINT [ "bash","ssl.sh","main","/var/wp/ssl"]