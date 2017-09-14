#!/bin/bash

if [ "$BACKUP_WINDOW" == "" ]; then

    BACKUP_WINDOW="0 6 * * * ";

fi

sed 's,{{ELASTICSEARCH_HOST}},'"${ELASTICSEARCH_HOST}"',g' -i /backup/functions.sh
sed 's,{{ELASTICSEARCH_PORT}},'"${ELASTICSEARCH_PORT}"',g' -i /backup/functions.sh
sed 's,{{DEBUG}},'"${DEBUG}"',g' -i /backup/functions.sh
sed 's,{{AZURE_STORAGE_ACCOUNT}},'"${AZURE_STORAGE_ACCOUNT}"',g' -i /backup/functions.sh
sed 's,{{AZURE_STORAGE_ACCESS_KEY}},'"${AZURE_STORAGE_ACCESS_KEY}"',g' -i /backup/functions.sh
sed 's,{{FILENAME}},'"${FILENAME}"',g' -i /backup/functions.sh
sed 's,{{CONTAINER}},'"${CONTAINER}"',g' -i /backup/functions.sh

if  [ "$ONE_SHOOT" == "true" ]; then

    . /backup/functions.sh;
    exit 0

else

    touch /var/log/cron.log;
    echo "$BACKUP_WINDOW /backup/variable.sh & /backup/functions.sh >> /var/log/cron.log 2>&1" >> job;
    echo "" >> job
    crontab job; cron;
    tail -f /var/log/cron.log;
    exit $?

fi
