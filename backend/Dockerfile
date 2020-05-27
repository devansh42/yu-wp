FROM python:alpine
RUN apk update && apk add docker 
ADD . .
RUN pip3 install -r requirements.txt

ENTRYPOINT [ "bash","entrypoint.sh" ]