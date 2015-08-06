#!/bin/bash

[ ${SOAJS_DEPLOY_DIR} ] && LOC=${SOAJS_DEPLOY_DIR} || LOC='/opt/'

[ ${1} ] && DEPLOY_FROM=${1} || DEPLOY_FROM='LOCAL'
WRK_DIR=${LOC}'soajs/node_modules'
GIT_BRANCH="develop"
MASTER_DOMAIN="soajs.org"

function program_is_installed(){
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}
function init(){
    echo $'Initializing and checking prerequisites ... '
    PRE_EXIT=0
    _SW_CHECK=$(program_is_installed node)
    if [ ${_SW_CHECK} == 0 ]; then
        echo $'\n ... Unable to find docker on your machine. PLease install node!'
        PRE_EXIT=1
    fi
    _SW_CHECK=$(program_is_installed mongo)
    if [ ${_SW_CHECK} == 0 ]; then
        echo $'\n ... Unable to find docker on your machine. PLease install mongo!'
        PRE_EXIT=1
    fi
    _SW_CHECK=$(program_is_installed nginx)
    if [ ${_SW_CHECK} == 0 ]; then
        echo $'\n ... Unable to find docker on your machine. PLease install nginx!'
        PRE_EXIT=1
    fi
    _SW_CHECK=$(program_is_installed npm)
    if [ ${_SW_CHECK} == 0 ]; then
        echo $'\n ... Unable to find docker on your machine. PLease install npm!'
        PRE_EXIT=1
    fi

    if [ ${PRE_EXIT} == 1 ]; then
        exit -1
    fi
}

function importData(){
    mongo --eval "db.stats()"
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        echo $'\n ...mongodb not running. PLease start mongodb!'
        exit -1
    else
        echo $'\n mongodb running! continue...'
    fi

    echo $'\n1- Importing core provisioned data ...'
    node index data import provision
    echo $'\n2- Importing URAC data...'
    node index data import urac
    echo $'\n--------------------------'
}

function setupNginx(){
	export SOAJS_NX_APIDOMAIN=dashboard-api.${MASTER_DOMAIN}
	export SOAJS_NX_DASHDOMAIN=dashboard.${MASTER_DOMAIN}
	export SOAJS_NX_APIPORT=80
	export SOAJS_NX_HOSTPREFIX=127.0.0.1
	export SOAJS_NX_DASHBOARDROOT=${WRK_DIR}"/soajs.dashboard/ui"
	mkdir -p ${WRK_DIR}"/nginx"

	export SOAJS_NX_LOC=${WRK_DIR}
	export SOAJS_NX_SETUPTYPE=local
	node ./FILES/nginx/index.js
	echo "DONE"
}

function startDashboard(){
	pushd ${WRK_DIR}
	killall node
    pushd soajs.controller
    node . &
    popd
    pushd soajs.urac
    node . &
    popd
    pushd soajs.dashboard
    node . &
    popd
    popd

    ps aux | grep node
    setupNginx
}

function uracSuccess(){
    if [ ${DEPLOY_FROM} == "NPM" ]; then
        npm install soajs.oauth
        npm install soajs.GCS
        npm install soajs.examples
    elif [ ${DEPLOY_FROM} == "GIT" ]; then
        git clone git@github.com:soajs/soajs.oauth.git --branch ${GIT_BRANCH}
        git clone git@github.com:soajs/soajs.GCS.git --branch ${GIT_BRANCH}
        git clone git@github.com:soajs/soajs.examples.git --branch ${GIT_BRANCH}
    else
        exit -1
    fi
    startDashboard
}
function uracFailure(){
    echo $'\n ... unable to install urac '${DEPLOY_FROM}' package. exiting!'
    exit -1
}
function dashSuccess(){
    if [ ${DEPLOY_FROM} == "NPM" ]; then
        npm install soajs.urac
    elif [ ${DEPLOY_FROM} == "GIT" ]; then
        git clone git@github.com:soajs/soajs.urac.git --branch ${GIT_BRANCH}
    else
        exit -1
    fi
    b=$!
    wait $b && uracSuccess || uracFailure
}
function dashFailure(){
    echo $'\n ... unable to install dashboard '${DEPLOY_FROM}' package. exiting!'
    exit -1
}
function controllerSuccess(){
    if [ ${DEPLOY_FROM} == "NPM" ]; then
        npm install soajs.dashboard
    elif [ ${DEPLOY_FROM} == "GIT" ]; then
        git clone git@github.com:soajs/soajs.dashboard.git --branch ${GIT_BRANCH}
    else
        exit -1
    fi
    b=$!
    wait $b && dashSuccess || dashFailure
}
function controllerFailure(){
    echo $'\n ... unable to install controller '${DEPLOY_FROM}' package. exiting!'
    exit -1
}
function soajsSuccess(){
    if [ ${DEPLOY_FROM} == "NPM" ]; then
        npm install soajs.controller
    elif [ ${DEPLOY_FROM} == "GIT" ]; then
        git clone git@github.com:soajs/soajs.controller.git --branch ${GIT_BRANCH}
    else
        exit -1
    fi
    b=$!
    wait $b && controllerSuccess || controllerFailure
}
function soajsFailure(){
    echo $'\n ... unable to install soajs '${DEPLOY_FROM}' package. exiting!'
    exit -1
}
function confirmDeployment(){

    echo $'\nYou are about to install at this location [ '${WRK_DIR}' ]'
    echo $'All its content will be replaced from [ '${DEPLOY_FROM}' ]'
    echo $'\nTo change the location set the environment variable SOAJS_DEPLOY_DIR'
    echo $'export SOAJS_DEPLOY_DIR="/opt/"'
    echo $'\n'
    printf '\7'
    read -p "Are you sure? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo $'\n... exiting!'
        exit -1
    fi
}
function exec(){
    if [ ${DEPLOY_FROM} == "NPM" ]; then
        confirmDeployment
        mkdir -p ${WRK_DIR}
        pushd ${WRK_DIR}
        export NODE_ENV=production
        npm install soajs
        b=$!
        wait $b && soajsSuccess || soajsFailure
    elif [ ${DEPLOY_FROM} == "GIT" ]; then
        confirmDeployment
        mkdir -p ${WRK_DIR}
        pushd ${WRK_DIR}
        git clone git@github.com:soajs/soajs.git --branch ${GIT_BRANCH}
        b=$!
        wait $b && soajsSuccess || soajsFailure
    elif [ ${DEPLOY_FROM} == "LOCAL" ]; then
        startDashboard
    else
        echo $'\nYou are trying to deploy from ['${LOCAL}']!'
        echo $'\n ... Deploy from must be one of the following [ NPM || GIT || LOCAL ]'
        exit -1
    fi
}

init
importData
exec
