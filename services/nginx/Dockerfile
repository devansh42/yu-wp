FROM nginx:alpine
ADD . /nginx
WORKDIR /nginx

RUN apk update && apk add  python3  certbot-nginx certbot   bash docker
RUN pip3 install s3cmd
RUN pip3 install -r requirements.txt

ENTRYPOINT [ "bash","entrypoint.sh" ]


