#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/vars
while getopts s:p:c: flag
do
    case "${flag}" in
        c) CLUSTER=${OPTARG};;
        p) PROJECT_ID=${OPTARG};;
        s) SERVICE_ACCOUNT=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

if [ -z ${SERVICE_ACCOUNT+x} ]; then
  echo "Missing SERVICE_ACCOUNT=$SERVICE_ACCOUNT (required)"
  usage
fi

echo "Running  $(basename "$0") with  PROJECT_ID=$PROJECT_ID ARGOLIS=$ARGOLIS SERVICE_ACCOUNT=$SERVICE_ACCOUNT CLUSTER=$CLUSTER REGION=$REGION ZONE=$ZONE"


#Service account creation
KEY_FILE=${SERVICE_ACCOUNT}.json
if gcloud iam service-accounts list --project $PROJECT_ID | grep -q $SERVICE_ACCOUNT; then
  echo "Service account $SERVICE_ACCOUNT has been found."
else
  echo "Creating service account... $SERVICE_ACCOUNT"
  gcloud iam service-accounts create $SERVICE_ACCOUNT \
      --description="Runs GitLab CI/CD jobs" \
      --display-name="GitLab-service-account"
fi

if [[ $ARGOLIS == 'true' ]]; then
  gcloud org-policies reset constraints/iam.disableServiceAccountKeyCreation --project $PROJECT_ID
fi

gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SERVICE_ACCOUNT@"${PROJECT_ID}".iam.gserviceaccount.com

# Provision Resources
bash "${DIR}"/iam_policy_binding.sh -p "$PROJECT_ID" -s "$SERVICE_ACCOUNT"


gcloud container clusters get-credentials $CLUSTER --region=$REGION --project $PROJECT_ID

#### Next Steps
echo "Created $SERVICE_ACCOUNT service account to be used with GitLab deployment."
ls "$KEY_FILE"

echo -e "Next Steps:
- 1. Download $KEY_FILE and use it for DRLS-GCP CI/CD Settings as a SERVICE_ACCOUNT_KEY for your deployment.
- 2. Install Gitlab Agent on the $CLUSTER cluster.
     You are already connected to the $CLUSTER cluster. To re-connect run:

gcloud container clusters get-credentials $CLUSTER --region=$REGION --project $PROJECT_ID"


