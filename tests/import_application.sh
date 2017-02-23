#!/bin/bash

test_import_good_application() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev
    remove_application $1
}

test_import_bad_application() {
    error=$(curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         -F file=@./fixture/broken-app.zip \
         -F name="test-app" \
         ${API_BASE_PATH}organizations/$APIGEE_ORG/apps | tail -n 1 | grep '{"message"')
    
    if [ "$error" == "" ]; then
        test_fail "should have failed to create application"
    fi
}

test_remove_application() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev
    remove_application $1

    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         ${API_BASE_PATH}organizations/$APIGEE_ORG/apps/$1/version/$2 > /dev/null

    check_failure_return $? "lookup application"
}

test_remove_running_application() {
    rev=$(import_application $1 "./fixture/app.zip")
    verify_application_exists $1 $rev

    json="{ \"deploymentName\": \"$1\", \"revision\": $rev }"

    deploy_application "$json"
    verify_deployment_exists_in_api $1
    sleep $DEPLOY_DELAY
    verify_deployment_exists_in_dispatcher $1

    
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         -X DELETE \
         ${API_BASE_PATH}organizations/$APIGEE_ORG/apps/$1 > /dev/null

    check_failure_return $? "remove application"

    verify_application_exists $1 $rev
    
    undeploy_application $1
    sleep $UNDEPLOY_DELAY
    remove_application $1
}

run_test "Import Good Application" test_import_good_application "test-app"

run_test "Import Application w/o package.json" test_import_bad_application

run_test "Remove Application" test_remove_application "test-app"

run_test "Remove Running Application" test_remove_running_application "test-app"


