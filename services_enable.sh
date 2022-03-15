#!/bin/bash
######
#
# This script sets your required APIs to execute GitLab CI/CD flow.
# Example call:
# bash ./services_enable.sh -p prior_auth_test
######

# ARGPARSE
while getopts p: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

echo "Enabling APIs for $PROJECT_ID ..."
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

## For Argolis
gcloud services enable orgpolicy.googleapis.com
gcloud org-policies reset constraints/compute.vmExternalIpAccess --project "${PROJECT_ID}"

##################################
# Now let's echo out our services for this account.
##################################
gcloud services list --enabled
