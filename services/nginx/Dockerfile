FROM nginx:alpine
ADD . /nginx
WORKDIR /nginx

RUN apk update && apk add certbot certbot-nginx python3-pip bash docker
ENTRYPOINT [ "./entrypoint.sh" ]


