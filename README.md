# gke-deploy-env
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [GCP Provisioning and GitLab Agent Installation](#gcp_agent)
  * [GCP Project](#gcp_project)
  * [Service Account](#service_account)
  * [Setting Up Environment](#setting_up_environment)
  * [GitLab Agent](#gitlab_agent)
- [GitLab CI/CD](#gitlab_ci_cd)

## Overview                 

These are manual steps for GCP Provisioning which are Pre-Requisite for GitLab CI/CD flow.
To be integrated with DTP ...   

These instructions guide you through:
- Creating GCP Project
- Provisioning resources (Service Account, enabling APIs, creating Cluster)
- Installing GitLab agent on the Cluster above

## Prerequisites  <a name="prerequisites"></a>

### GitLab Access
> Currently, this flow requires special access for the GitLab Repository and Container Registry, so a Personal Access Token is needed for the setup.
You will need to have permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization) and generated Personal Access Token with `read_registry` and `read_repository` scope.
In case of planning on contributing back, the scope needs also to include `write_registry` and `write_repository`.

- Create a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token) further referred as TOKEN.
- Save this token in your password management tool. It will not be accessible after this page is closed.

## GCP Provisioning and GitLab Agent Installation <a name="gcp_agent"></a>

### GCP Project
- Create GCP Project with a billing account or use an existing one. 
  * Take note of your Google Cloud Project ID. Moving forward, this will be referred to as `PROJECT_ID`.

### Service Account
- [Create a service account & download key JSON](https://cloud.google.com/docs/authentication/getting-started#creating_a_service_account). 
Moving forward,  name of the created service account will be referred to as `SERVICE_ACCOUNT`.


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

- Using Cloud Shell (or gcloud) to clone this repository using your Gitlab Token:
    ```shell
      git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env.git gke-deploy-env
    ```

- Execute Provisioning Step (to be integrated with DTP). This will:
  - Enable required APIs
  - Add required Role Bindings to the Service Account
  - Create Cluster (using Cluster name, network, zone and region as specified in [vars](vars) file).
  
  ```shell
  bash gke-deploy-env/provision.sh -p $PROJECT_ID -a $SERVICE_ACCOUNT
  ```

### GitLab Agent
Install GitLab Agent in the cluster created above. See Instructions [here](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html)
- Inside this [repository](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/.gitlab), [create the Agent's configuration file](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html#create-the-agents-configuration-file)
  ```shell
  .gitlab/agents/<agent-name>/config.yaml
  ```
- Go to [Kubernetes page of this project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/clusters) and select Actions->Connect with Agent.
  - Select the `agent-name` you used -> Register
  - Open a CLI and connect to the cluster you created in the step above. 
  - Run the docker `docker run` command.

## GitLab CI/CD
- Following variables created here need to be carried over:
  - AGENT_NAME: name of the agent just created and deployed. 
  - SERVICE_ACCOUNT_FILE: Downloaded Service Account JSON key
  - PROJECT_ID: ID of the created GCP project.
  
Now follow this [README](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/blob/main/GitLabREADME.md)







