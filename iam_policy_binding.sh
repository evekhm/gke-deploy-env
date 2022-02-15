#!/bin/bash
######
#
# This script sets your required service account policy bindings so you can use the GitLab CI/CD flow.
# Example call:
# bash ./iam_policy_binding.sh -p prior_auth_test -a gitlab-runner
######
while getopts a:p: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        a) SERVICE_ACCOUNT_NAME=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

echo "Using PROJECT_ID=$PROJECT_ID, SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME"
# REF
# https://cloud.google.com/iam/docs/understanding-roles#basic
 
# ROLE: resourcemanager.projectIamAdmin
# DESCRIPTION: Provides permissions to administer IAM policies on projects.
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/resourcemanager.projectIamAdmin"

#EK - prepare cluster script
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountCreator"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.workloadIdentityUser"

# EK needed to upload Cloud Storage Bucket for CDS Library
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/clouddeploy.jobRunner"

#EK: needed to list existing/create a new namespace when deploying to the GKE cluster
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.developer"

# This is too much in privs. Try to not use.
# Full control of all Compute Engine resources.
# Replace with compute.instanceAdmin?
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/compute.admin"

# Permissions to create, modify, and delete virtual machine instances. This includes permissions to create, modify, and delete disks, and also to configure Shielded VM settings.
# https://cloud.google.com/iam/docs/understanding-roles#compute-engine-roles
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/compute.instanceAdmin.v1"

# Provides full access to Cloud KMS resources, except encrypt and decrypt operations.
# https://cloud.google.com/iam/docs/understanding-roles#cloud-kms-roles
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/cloudkms.admin"

# Provides ability to use Cloud KMS resources for encrypt and decrypt operations only.
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# Provides access to all custom roles in the project.
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.roleAdmin"

# Impersonate service accounts (create OAuth2 access tokens, sign blobs or JWTs, etc).
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountTokenCreator"

# Permissions to create, modify, and delete networking resources, except for firewall rules and SSL certificates. 
#   The network admin role allows read-only access to firewall rules, SSL certificates, and instances (to view their ephemeral IP addresses). 
#   The network admin role does not allow a user to create, start, stop, or delete instances.
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/compute.networkAdmin"

# Full access to policies, access levels, and access zones
# https://cloud.google.com/iam/docs/understanding-roles#access-context-manager-roles
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/accesscontextmanager.policyAdmin"

# Create and manage service accounts.
# https://cloud.google.com/iam/docs/understanding-roles#service-accounts-roles
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountAdmin"


##################################
# Now let's echo out our policies for this account.
##################################
gcloud projects get-iam-policy  $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:$SERVICE_ACCOUNT_NAME"

# Specials for the Service Accounts
# This is needed to be able to access Container Registry within GCP Project  #EK
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$(gcloud projects describe "$PROJECT_ID" --format='get(projectNumber)')-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"