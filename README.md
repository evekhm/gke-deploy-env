# gke-deploy-env
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [GCP Provisioning]()
- [GitLab CI/CD]()

## Overview                 

These are manual steps for GCP Provisioning which are Pre-Requisite for GitLab CI/CD flow.
To be integrated with DTP ...   

## Prerequisites  <a name="prerequisites"></a>

### GitLab Access
> Currently, this flow requires special access for the GitLab Repository and Container Registry, so a Personal Access Token is needed for the setup.
You will need to have permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/epa) and generated Personal Access Token with `read_registry` and `read_repository` scope.
In case of planning on contributing back, the scope needs also to include `write_registry` and `write_repository`.

- Create a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token)
- Save this token in your password management tool. It will not be accessible after this page is closed.

## GCP Provisioning

### GCP Project
- Create GCP Project (tested for goggle org inside `gcct demos`).
- Take note of your Google Cloud Project ID. Moving forward, this will be referred to as `PROJECT_ID`.

### Service Account
- [Create a service account & download key JSON](https://cloud.google.com/docs/authentication/getting-started#creating_a_service_account). Moving forward, this will be referred to as `GCP_SERVICE_ACCOUNT`
Moving forward, this will be referred to as `SERVICE_ACCOUNT`.


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
- Create a root directory for the demo (we will call this `<drlsroot>` for the remainder of this and related setup guides).
   ```bash
   mkdir <drlsroot> && cd <drlsroot>
   ```
- Using Cloud Shell (or gcloud) clone this repository using your Gitlab Token (replace `TOKEN` below with your token)
    ```shell
      git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env.git gke-deploy-env
      cd gke-deploy-env
    ```

- Execute Provisioning Step (to be integrated with DTP). This will:
  - Enable required APIs
  - Add required Role Bindings to the Service Account
  - Create Cluster (as specified in `vars` file)
  
  ```shell
  bash ./provision.sh -p $PROJECT_ID -a $SERVICE_ACCOUNT
  ```

## GitLab Agent
Install GitLab Agent in the cluster created above. See Instructions [here](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html)
- Inside this repository, [create the Agent's configuration file](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html#create-the-agents-configuration-file)
  ```shell
  .gitlab/agents/<agent-name>/config.yaml
  ```
- Go to [Kubernetes page of this project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/clusters) and select Actions->Connect with Agent.
  - Select the `agent-name` you used -> Register
  - Open a CLI and connect to the cluster you want to install the agent in. 
  - Run the docker `docker run` command.

## GitLab CI/CD
- Following variables created here need to be carried over:
  - KUBE_AGENT=<agent_name>
  - PROJECT_ID=<your_project_id>
  - CLUSTER=<cluster_name>
  - Downloaded Service Account JSON key.
- Now follow this [README](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/blob/main/GitLabREADME.md)







