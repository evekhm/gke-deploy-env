PROJECT_ID=$(gcloud config get-value project)


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR"/SET

export GCP_SERVICE_ACCOUNT_EMAIL=${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud services enable artifactregistry.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com clouddeploy.googleapis.com iap.googleapis.com

if gcloud artifacts repositories describe $REPOSITORY --location=$REGION 2>/dev/null; then
  echo "Repository $REPOSITORY already exists in location $REGION"
else
  gcloud artifacts repositories create $REPOSITORY \
      --repository-format=docker \
      --location="$REGION" \
      --description="$REPOSITORY_DESC"
fi

if gcloud iam service-accounts describe "$GCP_SERVICE_ACCOUNT_EMAIL" 2>/dev/null; then
  echo "Service account ${GCP_SERVICE_ACCOUNT_EMAIL} has been found."
else
  gcloud iam service-accounts create "${GCP_SERVICE_ACCOUNT}" --project="${PROJECT_ID}"
fi


# writer
# gcloud projects add-iam-policy-binding ${PROJECT_ID}  --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID}  --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.admin"

# reader
# gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.reader"

# Add viewer rights for individual repository
gcloud artifacts repositories add-iam-policy-binding $REPOSITORY --location=$REGION --member="serviceAccount:${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/artifactregistry.reader"
#gcloud artifacts repositories add-iam-policy-binding $REPOSITORY --location=$REGION --member="serviceAccount:${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/artifactregistry.writer"
