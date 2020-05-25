FROM mysql:5.7
RUN apt update && apt -y install cron
ADD . .
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh
ENTRYPOINT ["bash","/run.sh"]
