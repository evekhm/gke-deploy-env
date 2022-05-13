#!/bin/bash
######
#
# This script sets your required APIs to execute GitLab CI/CD flow.
# Example call:
# bash ./services_enable.sh -p prior_auth_test
######

# ARGPARSE
while getopts p:A flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        A) ARGOLIS=true;;
        *) echo "Wrong arguments provided" && exit
    esac
done

echo "Running  $(basename "$0") with  PROJECT_ID=$PROJECT_ID ARGOLIS=$ARGOLIS"
echo "Enabling APIs for $PROJECT_ID ..."

if [[ -n "$ARGOLIS" ]]; then
  gcloud services enable orgpolicy.googleapis.com
  sleep 10
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
