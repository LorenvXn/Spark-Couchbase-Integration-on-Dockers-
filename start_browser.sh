#!/bin/bash

IP=`docker inspect $(docker ps  | sed -e 's/^\(.\{341\}\).*/\1/' | \
awk '{if($16 =="hahaa") print $1}') | grep IPAddress | awk 'NR==2 {print $NF}' | \
cut -f1 -d ',' | sed 's/["]//g' `

echo $IP

python -m webbrowser http://$IP:8091

##################################################################
# if the container hahaa is up and running
# the scripts find the IP of the container
# and will open the couchbase application that runs on port 8091 in a browser
###
