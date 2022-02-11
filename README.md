# gke-deploy-env
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)

## Overview                 

These are manual steps for GCP Provisioning which are Pre-Requisite for GitLab CI/CD flow.
To be integrated with DTP...   

## Prerequisites  <a name="prerequisites"></a>

### GitLab Access
> Currently, this flow requires special access for the GitLab Repository and Container Registry, so a Personal Access Token is needed for the setup.
You will need to have permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/epa) and generated Personal Access Token with `read_registry` and `read_repository` scope.
In case of planning on contributing back, the scope needs also to include `write_registry` and `write_repository`.

Check GitLab instructions [here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token).

## GCP Provisioning

### GCP Project
- Create GCP Project.
- Take note of your Google Cloud Project ID. Moving forward, this will be referred to as `PROJECT_ID`.

### Service Account
- [Create a service account & download key JSON](https://cloud.google.com/docs/authentication/getting-started#creating_a_service_account). Moving forward, this will be referred to as `GCP_SERVICE_ACCOUNT`
Moving forward, this will be referred to as `SERVICE_ACCOUNT` (Example: gitlab-runner).

### Create GKE Cluster
- Create Autopilot GKE Cluster [CLUSTER_NAME]


### Setting Up Environment
- Set Environment Variables and activate Project config:
  ```shell
  export PROJECT_ID=<your_project_id>
  export TOKEN=<your_gitlab_token>
  export SERVICE_ACCOUNT=<you_service_account_name>
  ```
  
  ```shell
  gcloud config set project $PROJECT_ID
  ```

- Using Cloud Shell (or gcloud) clone this repository using your Gitlab Token (replace `TOKEN` below with your token)
    ```shell
      git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env.git gke-deploy-env
      cd gke-deploy-env
    ```

- Enable following APIs: 
  ```shell
  bash ./enable_services.sh -p $PROJECT_ID
  ```

- Add required Role Bindings to the Service Account:
  ```shell
  bash ./iam_policy_binding.sh -p $PROJECT_ID -a $SERVICE_ACCOUNT
  ```
## GitLab Agent
- Install GitLab Agent on that cluster, you will need to specify it as KUBE_CONTEXT
  - .. add agent/..
  - ..

## GitLab CI/CD
- Now follow this README steps.... you will need the downloaded Service Account JSON key.






