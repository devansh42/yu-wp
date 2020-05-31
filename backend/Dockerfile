FROM python:alpine
RUN apk update && apk add bash 
ADD . .
RUN pip3 install -r requirements.txt
RUN pip3 install gunicorn
ENTRYPOINT [ "bash","entrypoint.sh" ]
