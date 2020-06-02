FROM golang:alpine AS pro
RUN apk update && apk add git bash
WORKDIR $GOPATH/src/wp/backend
ADD . .
RUN go get -d  
RUN go build -o $GOPATH/bin/backend .
WORKDIR /backend
RUN cp -r $GOPATH/bin .

FROM alpine
RUN apk update && apk add bash
WORKDIR /backend
COPY --from=pro /backend/bin/backend /backend/backend
ADD . .
RUN mkdir -p /var/log/backend /var/wp
ENTRYPOINT [ "/backend/backend" ]
