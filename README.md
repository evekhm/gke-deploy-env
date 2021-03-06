# gke-deploy-env
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [GCP Provisioning and GitLab Agent Installation](#gcp-agent)
  * [GCP Project](#gcp-project)
  * [Service Account](#service-account)
  * [Setting Up Environment](#setting-up-environment)
  * [GitLab Agent](#gitlab-agent)
- [GitLab CI/CD](#gitlab_ci_cd)

## Overview                 

These are manual steps for GCP Provisioning which are Pre-Requisite for GitLab CI/CD flow.

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
  
### Setting Up Environment

- Set Environment Variables and activate Project config:
  ```shell
  export PROJECT_ID=<your_project_id>
  export TOKEN=<your_gitlab_token>
  export USERNAME=<your_gitlab_username>
  ```
- If using Argolis environment:
  ```shell
  export ARGOLIS=true
  ```
- Optional variables that could be specified (to overwrite defaults):
  ```shell
    export CLUSTER=<cluster_name>
    export ZONE=<your_zone>
    export REGION=<your_region>
  ```  

- Activate Project config
    ```shell
    gcloud config set project $PROJECT_ID
    ```
  
### Git Lab Login

- To get access to GitLab sources following command needs to be run:
  ```shell
  docker login -u $USERNAME -p $TOKEN registry.gitlab.com
  ```

- Using Cloud Shell (or gcloud) to clone this repository using your Gitlab Token:
    ```shell
       git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env.git gke-deploy-env
    ```
### Provisioning

- Dry-run to see parameters and options
     ```shell
    ./provision
    ```

    Sample output:
  ```shell
  ./provision_cicd.sh -p <PROJECT_ID> [-c <CLUSTER>]  [-s <SERVICE_ACCOUNT>]   - for Gitlab CI/CD Integration
  ./provision_demo.sh -p <PROJECT_ID> [-c <CLUSTER>]                            - for Manual DEMO deployment
  
  Defaults:
  PROJECT_ID=you_project_id
  CLUSTER=pa-demo
  SERVICE_ACCOUNT=pa-development-gitlab-sa
  ZONE=us-central1-c
  REGION=us-central1
  ARGOLIS=false
  ```
  

  * Run provisioning:
    * For CICD:
      ```shell
      gke-deploy-env/provision_cicd.sh
      ```
    * For manual deployment:
      ```shell
      gke-deploy-env/provision_demo.sh
      ```    

  * This will:
      - Enable required APIs
      - Add required Role Bindings to the Service Account
      - Create Cluster (using Cluster name, network, zone and region as specified in [vars](vars) file).

### Install GitLab Agent <a name="gitlab-agent"></a>
Install GitLab Agent in the cluster created above. See explained steps on Gitlab [here](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html#create-the-agents-configuration-file)
- Inside this [repository folder](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/tree/main/.gitlab/agents), create the Agent's configuration file:
  ```shell
  .gitlab/agents/<agent-name>/config.sample.yaml
  ```
- Go to [Kubernetes page of this project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/clusters) and select Actions->Connect with Agent.
  - Select the `agent-name` you used -> Register
  - Open a CLI and connect to the cluster you created in the step above. 
  - Install using helm (command generated by GitLab)

## GitLab CI/CD <a name="gitlab_ci_cd"></a>
- Following variables created here need to be carried over:
  - AGENT_NAME: name of the agent just created and deployed. 
  - SERVICE_ACCOUNT_FILE: Downloaded Service Account JSON key
  - PROJECT_ID: ID of the created GCP project.
  
Now follow this [README](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/blob/main/GitLabREADME.md)







