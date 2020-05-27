FROM nginx:alpine
ADD . /nginx
WORKDIR /nginx

RUN apk update && apk add certbot certbot-nginx python3 python3-pip bash docker && pip3 install s3cmd

ENTRYPOINT [ "bash","entrypoint.sh" ]


