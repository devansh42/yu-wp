FROM python:alpine
RUN apk update && apk add bash 
ADD . .
RUN pip3 install -r requirements.txt

ENTRYPOINT [ "bash","entrypoint.sh" ]
