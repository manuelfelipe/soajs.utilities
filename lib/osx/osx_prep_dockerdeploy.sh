#!/bin/bash

# OSX deploy
# Brew required

xcode required?
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew upgrade
brew services
brew install homebrew/versions/node012 docker docker-machine mongodb
brew services
brew services stop mongodb

mkdir -p /opt/soajs/
cd /opt/soajs/
npm install soajs.utilities
cd /opt/soajs/soajs.utilities/lib/
./dockerDeploy.sh

echo ""
echo "Add these IPs to /etc/hosts or use the external IP:"
IPS=$(hostname -I | awk {' print $1 '})
echo "$IPS dashboard.soajs.org dashboard-api.soajs.org api.soajs.org api.mydomain.com"
