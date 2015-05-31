# Elasticsearch Notes
---------------------

## Install
Install Java
```bash
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java7-installer
java -version
```
Install Elasticsearch
```bash
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/elasticsearch/1.5/debian stable main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update && sudo apt-get install elasticsearch
sudo update-rc.d elasticsearch defaults 95 10
```

## [Configure](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html)

```bash
$ sudo swapoff -a
```
Also edit  `/etc/fstab` and comment out any lines that contain the word **`swap`**

Edit  `/etc/sysctl.conf`
```bash
vm.max_map_count=262144
```

Edit  `/etc/defaults/elasticsearch`
```bash
ES_HEAP_SIZE=2g
MAX_LOCKED_MEMORY=unlimited
```
Set `ES_MIN_MEM` amd `ES_MAX_MEM` to the same value

Edit  `/etc/security/limits.conf`
```bash
elasticsearch - nofile 65535
elasticsearch - memlock unlimited
```
Edit  '/etc/elasticsearch/elasticsearch.yml'
```yaml

index.number_of_replicas: 0
bootstrap.mlockall: true
http.max_content_length: 256mb
```

## Commands

List all indices
```bash
$ curl 'http://localhost:9200/_aliases?pretty=1'
```
Count all docs
```bash
$ curl 'http://localhost:9200/_all/count'
```
Delete all indices (DON'T DO THIS!!!!!)
```bash
$ curl -XDELETE 'http://localhost:9200/_all'
```

## Plug-Ins

### elasticsearch-kopf
```bash
$ cd /tmp
$ wget https://github.com/lmenezes/elasticsearch-kopf/archive/v1.5.2.zip
$ sudo -E /usr/share/elasticsearch/bin/plugin --install lmenezes/elasticsearch-kopf/1.5.2 -u file:///tmp/v1.5.2.zip
```
Now navigate to: [http://localhost:9200/_plugin/kopf](http://localhost:9200/_plugin/kopf)

### elasticsearch-head
```bash
$ cd /tmp
$ wget https://github.com/mobz/elasticsearch-head/archive/master.zip
$ sudo -E /usr/share/elasticsearch/bin/plugin --install mobz/elasticsearch-head -u file:///tmp/master.zip
```
Now navigate to: [http://<hostname>:9200/_plugin/head/](http://<hostname>:9200/_plugin/head/)

## Back-Up Data
### Install [elasticdump](https://github.com/taskrabbit/elasticsearch-dump)
```bash
$ npm install elasticdump -g
```
Now run the command
```bash
elasticdump --all=true --input=http://<host>:9200/ --output=/path/to/backup.json
```
To reload data from a backup
```bash
elasticdump --bulk=true --input=/path/to/backup.json --output=http://<host>:9200/
```

> Note: Disable your proxy settings first
```bash
unset http_proxy
unset HTTP_PROXY
```

```bash
curl -XPUT 'http://localhost:9200/_snapshot/my_backup' -d '{
    "type": "fs",
    "settings": {
        "location": "/mnt/folder/path",
        "compress": true
    }
}'
```


## Resources

 - https://engineering.opendns.com/2015/05/05/elasticsearch-you-know-for-logs/
 - https://www.loggly.com/blog/nine-tips-configuring-elasticsearch-for-high-performance/
 - http://www.elastic.co/guide/en/elasticsearch/reference/1.4/setup-configuration.html
