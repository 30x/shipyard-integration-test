#!/bin/bash

# ANSI COLORS
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BLUE="\033[0;34m"
LGRAY="\033[0;37m"
DGRAY="\033[1;30m"
RESET="\033[0m"

trap "exit 1" TERM
export TOP_PID=$$

check_success_return() {
    if [ "$1" -ne 0 ]; then
        echo -e "${DGRAY}${FUNCNAME[1]}: ${RED}$2${RESET}"
        kill -s TERM $TOP_PID
    fi
}

check_failure_return() {
    if [ "$1" -eq 0 ]; then
        echo -e "${DGRAY}${FUNCNAME[1]}: ${RED}$2${RESET}"
        kill -s TERM $TOP_PID
    fi
}

test_fail() {
    echo -e "${DGRAY}${FUNCNAME[1]}: ${RED}$1${RESET}"
    kill -s TERM $TOP_PID
}

run_test() {
    echo -en "${YELLOW}Testing $1 - ${RESET}"
    $2 $3 $4 $5 $6
    echo -e "${GREEN}Success${RESET}"
}
