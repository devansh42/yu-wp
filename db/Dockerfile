FROM mysql:5.7
RUN apt update && apt -y install cron
ADD . .
ENTRYPOINT ["bash","/run.sh"]
