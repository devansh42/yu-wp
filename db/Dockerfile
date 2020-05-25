FROM mysql:5.7
RUN apt update && apt -y install cron vim
ADD . .
ENTRYPOINT ["bash","/run.sh"]
