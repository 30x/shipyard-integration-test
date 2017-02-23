#!/bin/bash

import_application() {
    header_file=$(mktemp /tmp/shipyard-test.XXXXXX)
    # Import Application
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         -D $header_file \
         -o /dev/null \
         -F file=@$2 \
         -F name=$1 \
         -F envVar="SOME_VAR=abc1234" \
         -F envVar="OTHER_VAR=other" \
         ${API_BASE_PATH}organizations/$APIGEE_ORG/apps

    check_success_return $? "create application"

    # return rev number
    location=$(cat $header_file | grep Location | cut -d " " -f 2 | sed $'s/\r//')
    rev_num="$(basename $location)"
    rm -f $header_file
    echo $rev_num
}

verify_application_exists() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         ${API_BASE_PATH}organizations/$APIGEE_ORG/apps/$1/version/$2 > /dev/null

    check_success_return $? "lookup application"
}

remove_application() {
    curl --fail "${DEFAULT_CURL_ARGS[@]}" \
         -X DELETE \
         ${API_BASE_PATH}organizations/$APIGEE_ORG/apps/$1 > /dev/null

    check_success_return $? "remove application"
}
