#!/usr/bin/env bash

# To Be Provisioned by DTP
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export USE_GKE_GCLOUD_AUTH_PLUGIN=False

source "$DIR"/vars

while getopts p:c:A flag
do
    case "${flag}" in
        c) CLUSTER=${OPTARG};;
        p) PROJECT_ID=${OPTARG};;
        A) ARGOLIS=-A;;
        *) echo "Wrong arguments provided" && exit
    esac
done


usage(){
  echo " $(basename "$0")  -p <PROJECT_ID> [ -s <SERVICE_ACCOUNT_NAME> -c <CLUSTER_NAME> -A ]"
  exit 1
}
# 1. check for ENV variables to be set
if [ -z ${PROJECT_ID+x} ]; then
  echo "Missing PROJECT_ID=$PROJECT_ID (required)"
  usage
fi


echo "Running  $(basename "$0") with  PROJECT_ID=$PROJECT_ID ARGOLIS=$ARGOLIS CLUSTER=$CLUSTER REGION=$REGION ZONE=$ZONE"

gcloud config set project $PROJECT_ID

bash "${DIR}"/services_enable.sh -p "$PROJECT_ID" $ARGOLIS
bash "${DIR}"/create_cluster.sh -p "$PROJECT_ID" -c "$CLUSTER"