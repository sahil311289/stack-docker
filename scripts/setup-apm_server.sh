#!/bin/bash

set -euo pipefail

cacert=/usr/share/apm_server/config/ca/ca.crt
# Wait for ca file to exist before we continue. If the ca file doesn't exist
# then something went wrong.
while [ ! -f $cacert ]
do
  sleep 2
done
ls -l $cacert

es_url=https://elasticsearch:9200
# Wait for Elasticsearch to start up before doing anything.


while [[ "$(curl -u "elastic:${ELASTIC_PASSWORD}" --cacert $cacert -s -o /dev/null -w '%{http_code}' $es_url)" != "200" ]]; do
    sleep 5
done

# Set the password for the apm_server user.
# REF: https://www.elastic.co/guide/en/x-pack/6.0/setting-up-authentication.html#set-built-in-user-passwords
until curl -u "elastic:${ELASTIC_PASSWORD}" --cacert $cacert -s -H 'Content-Type:application/json' \
     -XPUT $es_url/_xpack/security/user/apm_server/_password \
     -d "{\"password\": \"${ELASTIC_PASSWORD}\"}"
do
    sleep 2
    echo Retrying...
done


echo "=== CREATE Keystore ==="
if [ -f /config/apm_server/apm-server.keystore ]; then
    echo "Remove old apm-server.keystore"
    rm /config/apm_server/apm-server.keystore
fi
/usr/share/apm_server/bin/apm_server-keystore create
echo "Setting elasticsearch.password: $ELASTIC_PASSWORD"
echo "$ELASTIC_PASSWORD" | /usr/share/apm_server/bin/apm_server-keystore add 'elasticsearch.password' -x

mv /usr/share/apm_server/data/apm-server.keystore /config/apm_server/apm-server.keystore
