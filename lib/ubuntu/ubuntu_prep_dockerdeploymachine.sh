#!/bin/bash

# Tested with Ubuntu 14.04.4
# Automated install of SOAJS dockerdeploy.sh

apt-get update
apt-get install -y npm libkrb5-dev make g++ build-essential nodejs mongodb

curl -fsSL https://get.docker.com/ | sh

ln -s /usr/bin/nodejs /usr/bin/node
service mongodb stop
mkdir /opt/soajs/
cd /opt/soajs/
npm install soajs.utilities
cd /opt/soajs/soajs.utilities/lib/
./dockermachineDeploy.sh








