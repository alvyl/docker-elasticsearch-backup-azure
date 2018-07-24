# Docker-Elasticsearch-backup-azure

container to backup your elasticserch database's to Microsoft Azure Storare.

## Initial setup on elasticsearch server before backup

To work with Azure Repository, the [Azure Repository plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-azure.html) from the official [ES Repository Plugin home page](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository.html) is to be installed on the machine running Elasticsearch.

Please refer to the following documentations related to [usage](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-azure-usage.html) and [settings](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-azure-repository-settings.html) as provided by Elasticsearch.

## Environment Variables

- _`$CONTAINER`_ - Container name in azure
- _`$AZURE_STORAGE_ACCOUNT`_ - Name of Azure Storare Account
- _`$AZURE_STORAGE_ACCESS_KEY`_ - Acess Key for Storage Account
- _`$ELASTICSEARCH_PORT`_ - Port to connect with elasticsearch. default 3306  
- _`$ELASTICSEARCH_HOST`_ - Host where elasticsearch is running
- _`$FILENAME`_ - Name to file in Azure Storage. Default name `default-date +"%Y-%m-%d_%H-%M"` output example `default-2015-08-03_17-58`
- _`$ONE_SHOOT`_ - If true the container make the backup and exit, else the container still running and schedule a job in crontab. default false a backup window.
- _`$DEBUG`_ - If true will give you the value of all variables in terminal. default to false

## To run the docker image

```bash
docker run ---rm --name elasticsearch-backup \
-e "ONE_SHOOT=true" \
-e "FILENAME=backup"
-e "AZURE_STORAGE_ACCOUNT=teste-azure"
-e "AZURE_STORAGE_ACCESS_KEY=ashdgashdgasdsa--dadcdsfsd/sdfd--"
-e "CONTAINER=sql-backup" \
-e "ELASTICSEARCH_HOST=test.elasticsearch.com" \
alvyl/docker-elasticsearch-backup-azure

```

This will upload to Azure Storare a file named `default-2018-06-07_12-19-29.tar.gz` and after that the
container will stop.

### Building image

```bash
docker build -t alvyl/docker-elasticsearch-backup-azure .
```

**NOTE**: This code is tested in v2.4 and version - 6.3

---
### Steps for Elasticsearch backup in v2.4.X

1. For elasticsearch 2.4 version we have to install elasticsearch driver. Run the following command from the elastic search installation folder.
    ```sudo bin/plugin install cloud-azure```

2. To enable Azure repositories, you have first to set your azure storage settings in elasticsearch.yml file

    ```ruby
    cloud:
        azure:
            storage:
                my_account:
                    account: your_azure_storage_account
                    key: your_azure_storage_key
    ```

3. For latest es version, please refer to the official documentations.

#### Useful links for v2.4

1. Repository Plugin Home: https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/repository.html
1. Azure Plugin: https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/cloud-azure-repository.html
