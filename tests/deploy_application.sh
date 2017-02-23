#!/bin/bash

test_deploy_basic() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev

    json="{ \"deploymentName\": \"$1\", \"revision\": $rev }"

    deploy_application "$json"
    verify_deployment_exists_in_api $1
    sleep $DEPLOY_DELAY
    
    verify_deployment_exists_in_dispatcher $1
    undeploy_application $1
    sleep $UNDEPLOY_DELAY
    remove_application $1
}

test_deploy_with_paths() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev

    json="{ \"deploymentName\": \"$1\", \"revision\": $rev, \"edgePaths\": [{\"basePath:\": \"/testing\", \"containerPort\": \"3000\", \"targetPath\": \"/hello\"}] }"

    deploy_application "$json"
    verify_deployment_exists_in_api $1
    sleep $DEPLOY_DELAY
    
    verify_deployment_exists_in_dispatcher $1
    undeploy_application $1
    sleep $UNDEPLOY_DELAY
    remove_application $1
}

test_env_vars() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev
    
    json="{ \"deploymentName\": \"$1\", \"revision\": $rev, \"envVars\": [{\"name\": \"TEST_VAR\", \"value\": \"abc123\", \"OTHER_VAR\": \"new-val\"}] }"

    deploy_application "$json"
    verify_deployment_exists_in_api $1
    sleep $DEPLOY_DELAY

    secret=$(get_routing_secret_for_org)
    get_hosts_for_org | while read host;
    do
        resp=$(curl -s --fail \
             -H "Authorization:Bearer $TOKEN" \
             -H "Host:$host" \
             -H "$API_ROUTING_KEY_HEADER:$secret" \
             ${API_BASE_PATH}${1})
        check_success_return $? "deployment should be routable"

        someVar=$(echo $resp | jq -r .env.SOME_VAR)
        if [ "$someVar" != "abc1234" ]; then
            test_fail "SOME_VAR should equal abc1234"
        fi
        
        testVar=$(echo $resp | jq -r .env.TEST_VAR)
        if [ "$testVar" != "abc123" ]; then
            test_fail "TEST_VAR should equal abc123"
        fi
        # Test that env in deployment json overrides env from application image
        otherVar=$(echo $resp | jq -r .env.OTHER_VAR)
        if [ "$otherVar" != "new-val" ]; then
            test_fail "OTHER_VAR updating default ENV on application should be deployments env value"
        fi
    done

    undeploy_application $1
    sleep $UNDEPLOY_DELAY
    remove_application $1
}

test_remove_deployment() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev

    json="{ \"deploymentName\": \"$1\", \"revision\": $rev }"

    deploy_application "$json"
    verify_deployment_exists_in_api $1
    sleep $DEPLOY_DELAY
    
    verify_deployment_exists_in_dispatcher $1
    undeploy_application $1
    sleep $UNDEPLOY_DELAY

    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         ${API_BASE_PATH}environments/$APIGEE_ORG:$APIGEE_ENV/deployments/$1 > /dev/null

    check_failure_return $? "deployment should not exist in api"

    secret=$(get_routing_secret_for_org)
    get_hosts_for_org | while read host;
    do
        curl -s --fail \
             -H "Authorization:Bearer $TOKEN" \
             -H "Host:$host" \
             -H "$API_ROUTING_KEY_HEADER:$secret" \
             ${API_BASE_PATH}${1} > /dev/null

        check_failure_return $? "deployment should not be routable"
    done

    remove_application $1
}




run_test "Deploy Application" test_deploy_basic "test-app"

# Failing
#run_test "Deploy Application with Paths" test_deploy_with_paths "test-app"

# Failing
#run_test "Deploy Application with Env Vars" test_env_vars "test-app"

run_test "Remove Deployment" test_remove_deployment "test-app"



