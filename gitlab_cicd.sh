#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/vars
while getopts s:p:c:A flag
do
    case "${flag}" in
        c) CLUSTER=${OPTARG};;
        p) PROJECT_ID=${OPTARG};;
        A) ARGOLIS=true;;
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
if gcloud iam service-accounts list --project $PROJECT_ID | grep -q $SERVICE_ACCOUNT; then
  echo "Service account $SERVICE_ACCOUNT has been found."
else
  echo "Creating service account... $SERVICE_ACCOUNT"
  gcloud iam service-accounts create $SERVICE_ACCOUNT \
      --description="Runs GitLab CI/CD jobs" \
      --display-name="GitLab-service-account"
fi

gcloud org-policies reset constraints/iam.disableServiceAccountKeyCreation --project $PROJECT_ID
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SERVICE_ACCOUNT@"${PROJECT_ID}".iam.gserviceaccount.com

# Provision Resources
bash "${DIR}"/iam_policy_binding.sh -p "$PROJECT_ID" -a "$SERVICE_ACCOUNT"
bash "${DIR}"/create_cluster.sh -p "$PROJECT_ID" -c "$CLUSTER"

gcloud container clusters get-credentials $CLUSTER --region=$REGION --project $PROJECT_ID

#### Next Steps
echo "Created $SERVICE_ACCOUNT service account to be used with GitLab deployment."
echo -e "Next Steps:
- 1. Download $KEY_FILE and use it for DRLS-GCP CI/CD Settings.

 ls
 cat $KEY_FILE

- 2. Install Gitlab Agent on the $CLUSTER cluster.
     You are already connected to the $CLUSTER cluster. To re-connect run:

gcloud container clusters get-credentials $CLUSTER --region=$REGION --project $PROJECT_ID"


