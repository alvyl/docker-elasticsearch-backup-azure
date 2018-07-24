#!/bin/bash

DATETIME=`date +"%Y_%m_%d_%H_%M_%S"`

make_backup () {

    export FILENAME={{FILENAME}}
    export CONTAINER={{CONTAINER}}
    export ELASTICSEARCH_HOST={{ELASTICSEARCH_HOST}}
    export ELASTICSEARCH_PORT={{ELASTICSEARCH_PORT}}
    export DEBUG={{DEBUG}}
    export BACKUP_REPOSITORY={{BACKUP_REPOSITORY}}

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
        echo "######################################"
    else
        echo "No debug"
    fi

    backupResult=$(curl -s -o /dev/null -w "%{http_code}" -XGET $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/$BACKUP_REPOSITORY)

    if [[ "$backupResult" == "404" ]]; then
        curl -X PUT $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/$BACKUP_REPOSITORY -d '{ "type": "azure", "settings": {  "container": "elasticsearch-snapshots","compress": true} }' --header "content-type: application/JSON"
    fi

    snapshotName=$FILENAME-$(date +%s | sha256sum | base64 | head -c 16 | tr '[:upper:]' '[:lower:]')-$DATETIME

    # Initialise snapshot
    res=$(curl -X PUT $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_snapshot/$BACKUP_REPOSITORY/$snapshotName?wait_for_completion=true)

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

    if  [ "$?" != "0" ]; then
        exit 1
    fi
}

make_backup;
