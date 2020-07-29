#!/bin/sh

set -e 

# Get latest odo binary
sudo wget https://mirror.openshift.com/pub/openshift-v4/clients/odo/latest/odo-linux-amd64 2> /dev/null > /dev/null
sudo chmod +x odo-linux-amd64
sudo mv odo-linux-amd64 /usr/local/bin/odo

## Get odo version
odo version