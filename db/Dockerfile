FROM mysql:5.7
RUN apt update && apt -y install cron vim python3 python3-pip && pip3 install s3cmd
ADD . .
ENTRYPOINT ["bash","/run.sh"]
