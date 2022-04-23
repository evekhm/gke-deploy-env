#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
# Required Settings:
# -p PROJECT_ID

#Optional
# Possible settings:
#    export CLUSTER=<cluster-name>
#    export REGION=<your-region>
#    export ZONE=<your-zone>

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export USE_GKE_GCLOUD_AUTH_PLUGIN=False
while getopts s:p:c:a flag
do
    case "${flag}" in
        c) CLUSTER=${OPTARG};;
        p) PROJECT_ID=${OPTARG};;
        a) ARGOLIS=true;;
        s) SERVICE_ACCOUNT=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

usage(){
  echo " $(basename "$0")  [ -p <PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -c <CLUSTER_NAME> -a ]"
  exit 1
}
# 1. check for ENV variables to be set
if [ -z ${PROJECT_ID+x} ]; then
  echo "Missing PROJECT_ID=$PROJECT_ID"
  echo "Either set PROJECT_ID as env variable or provide it as input parameter  $(basename "$0") -p <PROJECT_ID>"
  usage
fi

## Download sources from Gitlab
#docker login -u $USERNAME -p $TOKEN registry.gitlab.com
#WORKDIR=${WORKDIR:-$(pwd)/argolis-pa-demo}
#if [ -d "$WORKDIR" ]; then
#  echo "$WORKDIR already exists, please remove/rename existing folder or set WORKDIR environment variable to a different location"
#  exit 1
#fi
#mkdir "$WORKDIR" && cd "$WORKDIR"
#DIR=gke-deploy-env
#git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env.git $DIR
#source "$DIR"/vars

source "$DIR"/vars
SERVICE_ACCOUNT=$USERNAME-pa
KEY_FILE=${SERVICE_ACCOUNT}.json

echo "Running  $(basename "$0") with  PROJECT_ID=$PROJECT_ID  SERVICE_ACCOUNT=$SERVICE_ACCOUNT USERNAME=$USERNAME GITLAB_AGENT=$GITLAB_AGENT WORKDIR=$WORKDIR CLUSTER=$CLUSTER REGION=$REGION ZONE=$ZONE"


gcloud config set project $PROJECT_ID

# Enable services
bash "${DIR}"/services_enable.sh -p "$PROJECT_ID"

if [[ $ARGOLIS == 'true' ]]; then
  gcloud services enable orgpolicy.googleapis.com
  gcloud org-policies reset constraints/compute.vmExternalIpAccess --project $PROJECT_ID
  gcloud org-policies reset constraints/iam.disableServiceAccountKeyCreation --project $PROJECT_ID
fi

# 3. Service account creation
gcloud iam service-accounts create $SERVICE_ACCOUNT
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SERVICE_ACCOUNT@"${PROJECT_ID}".iam.gserviceaccount.com

# Provision Resources
bash "${DIR}"/iam_policy_binding.sh -p "$PROJECT_ID" -a "$SERVICE_ACCOUNT"
bash "${DIR}"/create_cluster.sh -p "$PROJECT_ID" -c "$CLUSTER"

gcloud container clusters get-credentials $CLUSTER --region=$REGION --project $PROJECT_ID

#### Next Steps
echo -e " Next Steps:
- 1. Download $KEY_FILE and use it for DRLS-GCP CI/CD Settings.
- 2. Install Gitlab Agent on the $CLUSTER cluster. Connect to the cluster:
    gcloud container clusters get-credentials $CLUSTER --region=$REGION --project $PROJECT_ID"


