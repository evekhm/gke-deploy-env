#!/usr/bin/env bash

# To Be Provisioned by DTP
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export USE_GKE_GCLOUD_AUTH_PLUGIN=False
while getopts a:p: flag
do
    case "${flag}" in
        a) SERVICE_ACCOUNT=${OPTARG};;
        p) PROJECT_ID=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

bash "${DIR}"/services_enable.sh -p "$PROJECT_ID"
bash "${DIR}"/iam_policy_binding.sh -p "$PROJECT_ID" -a "$SERVICE_ACCOUNT"
bash "${DIR}"/create_cluster.sh -p "$PROJECT_ID"