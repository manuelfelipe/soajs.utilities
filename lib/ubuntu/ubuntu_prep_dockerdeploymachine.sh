# brew install node012
# node v0.12.12 needed
#
# make sure docker is working

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








