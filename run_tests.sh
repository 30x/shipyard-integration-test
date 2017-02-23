#!/bin/bash

#set -e
#set -x

source ./defaults.sh
source ./common.sh

# Load Helpers
source ./kiln_helpers.sh
source ./enrober_helpers.sh


# Run tests
source ./tests/import_application.sh
source ./tests/deploy_application.sh



