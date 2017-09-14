FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y -q && \
  apt-get install -y nodejs-legacy curl wget npm cron jq && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN npm install -g n azure-cli
RUN n 0.12.7

RUN mkdir -p /backup
ADD . /backup
RUN chmod 0755 /backup/*

VOLUME /usr/share/elasticsearch/backup

ENTRYPOINT ["/backup/backup.sh"]
