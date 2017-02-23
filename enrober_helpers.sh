#!/bin/bash

deploy_application() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         -o /dev/null \
         -H "Content-Type: application/json" \
         --data "$1" \
         ${API_BASE_PATH}environments/$APIGEE_ORG:$APIGEE_ENV/deployments

    check_success_return $? "should have created deployment"
}

verify_deployment_exists_in_api() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         ${API_BASE_PATH}environments/$APIGEE_ORG:$APIGEE_ENV/deployments/$1 > /dev/null

    check_success_return $? "deployment should exist in api"
}

get_hosts_for_org() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         ${API_BASE_PATH}environments/$APIGEE_ORG:$APIGEE_ENV | jq -r '.edgeHosts | to_entries[] | .key'
}

get_routing_secret_for_org() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         ${API_BASE_PATH}environments/$APIGEE_ORG:$APIGEE_ENV | jq -r '.apiSecret'
}

verify_deployment_exists_in_dispatcher() {
    secret=$(get_routing_secret_for_org)
    get_hosts_for_org | while read host;
    do
        curl -s --fail \
             -H "Authorization:Bearer $TOKEN" \
             -H "Host:$host" \
             -H "$API_ROUTING_KEY_HEADER:$secret" \
             ${API_BASE_PATH}${1} > /dev/null

        check_success_return $? "deployment should be routable"

        curl -s --fail \
             -H "Authorization:Bearer $TOKEN" \
             -H "Host:$host" \
             ${API_BASE_PATH}${1} > /dev/null

        check_failure_return $? "deployment should reuturn 403 when no routing key is used"
    done

    
}

undeploy_application() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         -X DELETE \
         ${API_BASE_PATH}environments/$APIGEE_ORG:$APIGEE_ENV/deployments/$1 > /dev/null

    check_success_return $? "should have removed deployment"
}
