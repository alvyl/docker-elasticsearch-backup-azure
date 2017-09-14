#!/bin/bash

DATETIME=`date +"%Y-%m-%d_%H-%M-$S"`

make_backup () {

    export FILENAME={{FILENAME}}
    export CONTAINER={{CONTAINER}}
    export ELASTICSEARCH_HOST={{ELASTICSEARCH_HOST}}
    export ELASTICSEARCH_PORT={{ELASTICSEARCH_PORT}}
    export DEBUG={{DEBUG}}
    export AZURE_STORAGE_ACCOUNT={{AZURE_STORAGE_ACCOUNT}}
    export AZURE_STORAGE_ACCESS_KEY={{AZURE_STORAGE_ACCESS_KEY}}
    export BACKUP_LOCATION={{BACKUP_LOCATION}}

    if [ "$ELASTICSEARCH_PORT" == "" ]; then
        export ELASTICSEARCH_PORT="9200";
    fi

    if [ "$FILENAME" == "" ]; then
        export FILENAME="default";
    fi

    if [ "$DEBUG" == "true" ]; then
        echo "######################################"
        echo "FILENAME = $FILENAME"
        echo "CONTAINER = $CONTAINER"
        echo "ELASTICSEARCH_HOST = $ELASTICSEARCH_HOST"
        echo "ELASTICSEARCH_PORT = $ELASTICSEARCH_PORT"
        echo "AZURE_STORAGE_ACCOUNT = $AZURE_STORAGE_ACCOUNT"
        echo "AZURE_STORAGE_ACCESS_KEY = $AZURE_STORAGE_ACCESS_KEY "
        echo "######################################"
    else
        echo "No debug"
    fi

    BACKUP_LOCATION="/usr/share/elasticsearch/backup"
    touch $BACKUP_LOCATION/snapshot-backup_snapshot

    backupResult=$(curl -s -o /dev/null -w "%{http_code}" -XGET $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/backup)

    if [[ "$backupResult" == "404" ]]; then
        curl -X PUT -d '{ "type": "fs", "settings": { "compress": false, "location": "'$BACKUP_LOCATION'" } }' $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/backup
    fi

    snapshotName=$(date +%s | sha256sum | base64 | head -c 16 | tr '[:upper:]' '[:lower:]')

    # Initialise snapshot
    res=$(curl -X PUT $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/backup/$snapshotName?wait_for_completion=true)

    # res should look similar to this:
    # {"snapshot":{"snapshot":"backup_snapshot","version_id":1070499,"version":"1.7.4","indices":[],"state":"SUCCESS","start_time":"2016-08-31T13:32:07.883Z","start_time_in_millis":1472650327883,"end_time":"2016-08-31T13:32:07.925Z","end_time_in_millis":1472650327925,"duration_in_millis":42,"failures":[],"shards":{"total":0,"failed":0,"successful":0}}}

    snapshotResult=$(echo $res | jq -r '.snapshot.state')

    # exit if last command have problems
    if  [ "$snapshotResult" != "SUCCESS" ]; then
        echo "Error occurred in database dump process. Exiting now"

        if [ "$DEBUG" == "true" ]; then
            echo  $res
        fi

        exit 1
    fi

    # compress the file
    tar -zcvf $FILENAME-$DATETIME.tar.gz $BACKUP_LOCATION/*

    # Send to cloud storage
    /usr/local/bin/azure telemetry --disable
    /usr/local/bin/azure storage container create $CONTAINER -c "DefaultEndpointsProtocol=https;BlobEndpoint=https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/;AccountName=$AZURE_STORAGE_ACCOUNT;AccountKey=$AZURE_STORAGE_ACCESS_KEY"
    /usr/local/bin/azure storage blob upload -q $FILENAME-$DATETIME.tar.gz $CONTAINER -c "DefaultEndpointsProtocol=https;BlobEndpoint=https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/;AccountName=$AZURE_STORAGE_ACCOUNT;AccountKey=$AZURE_STORAGE_ACCESS_KEY"

    # Remove file to save space
    rm -fR *.tar.gz

    curl -X DELETE $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/backup/$snapshotName

    if  [ "$?" != "0" ]; then
        exit 1
    fi
}

make_backup;
