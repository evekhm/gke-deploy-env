#!/bin/bash
######
#
# This script sets your required APIs to execute GitLab CI/CD flow.
# Example call:
# bash ./services_enable.sh -p prior_auth_test
######
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR"/vars
while getopts p: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        *)
    esac
done

if [ -z ${PROJECT_ID+x} ]; then
  echo "Missing PROJECT_ID=$PROJECT_ID (required)"
  exit 1
fi

echo "Running  $(basename "$0") with  PROJECT_ID=$PROJECT_ID ARGOLIS=$ARGOLIS"

gcloud config set project $PROJECT_ID

echo "Enabling APIs for $PROJECT_ID ..."

if [[ $ARGOLIS == 'true' ]]; then
  gcloud services enable orgpolicy.googleapis.com
  sleep 15
  gcloud org-policies reset constraints/compute.vmExternalIpAccess --project "${PROJECT_ID}"
fi

declare -a ServiceArray=(\
        "apigateway.googleapis.com" \
        "storage.googleapis.com" \
        "cloudkms.googleapis.com" \
        "cloudresourcemanager.googleapis.com" \
        "compute.googleapis.com" \
        "container.googleapis.com" \
        "containerregistry.googleapis.com" \
        "iam.googleapis.com" \
        "iamcredentials.googleapis.com" \
        "secretmanager.googleapis.com" \
        "servicecontrol.googleapis.com" \
        "servicemanagement.googleapis.com" \
        "serviceusage.googleapis.com")

for s in "${ServiceArray[@]}"; do
    gcloud services enable --project "${PROJECT_ID}" "$s"
done


##################################
# Now let's echo out our services for this account.
##################################
gcloud services list --enabled
