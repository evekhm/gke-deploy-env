#!/usr/bin/env bash

# To Be Provisioned by DTP
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export USE_GKE_GCLOUD_AUTH_PLUGIN=False

bash "${DIR}"/services_enable.sh "$@"
bash "${DIR}"/create_cluster.sh "$@"