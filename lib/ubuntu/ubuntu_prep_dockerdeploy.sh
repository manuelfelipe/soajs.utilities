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
./dockerDeploy.sh

echo ""
echo "Add these IPs to /etc/hosts or use the external IP:"
IPS=$(hostname -I | awk {' print $1 '})
echo "$IPS dashboard.soajs.org dashboard-api.soajs.org api.soajs.org api.mydomain.com"
