#!/bin/bash

# Shipyard API Base Path and Host
API_BASE_PATH=${API_BASE_PATH:-http://192.168.99.100:30555/}
API_HOST=${API_HOST:-api.shipyard.dev}

API_ROUTING_KEY_HEADER=${API_ROUTING_KEY_HEADER:-"x-routing-api-key"}

# Apigee Test Org use mine for now i guess
APIGEE_ORG=${APIGEE_ORG:-adammagaluk1}
APIGEE_ENV=${APIGEE_ENV:-test}

# SSO Login Default to e2e
SSO_LOGIN_URL=${SSO_LOGIN_URL:-https://login.e2e.apigee.net}
TOKEN=$(SSO_LOGIN_URL=$SSO_LOGIN_URL get_token)

if [ "$DEBUG" == "true" ]; then
    set -x
    CURL_OUTPUT="-v"
else
    CURL_OUTPUT="-s"
fi

DEFAULT_CURL_ARGS=($CURL_OUTPUT -H "Authorization:Bearer $TOKEN" -H "Host:$API_HOST")

# Time to wait after deploying or undeploying an application for other api calls
DEPLOY_DELAY=${DEPLOY_DELAY:-5}
UNDEPLOY_DELAY=${UNDEPLOY_DELAY:-30}
