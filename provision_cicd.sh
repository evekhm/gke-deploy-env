#!/usr/bin/env bash

# To Be Provisioned by DTP
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bash "${DIR}"/provision_demo.sh "$@"

# Create Service Account for CI/CD Gitlab Agent Jobs
bash "${DIR}"/gitlab_cicd.sh "$@"
