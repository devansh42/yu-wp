FROM golang:alpine AS build
RUN apk update && apk add git
WORKDIR $GOPATH/src/wp/worker
COPY . .
RUN go get -d -v
RUN go build -o $GOPATH/bin/worker .
WORKDIR /worker 
RUN cp -r $GOPATH/bin .

FROM nginx:alpine 
RUN apk update && apk add python3 certbot certbot-nginx bash docker
RUN pip3 install s3cmd
RUN mkdir /etc/nginx/sites-available
WORKDIR /worker
COPY --from=build /worker/bin/worker /worker/worker
ADD . .
RUN mkdir -p /var/log/wp/site /var/log/wp/ssl

ENTRYPOINT [ "bash","entrypoint.sh" ]


