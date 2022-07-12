# Artifact Registry Authentication

This demonstrates how to use Artifact Registry from a fresh Argolis GCP Project.
The sample steps include:

- Network creation (including NAT), Artifact Registry repository creation, Service Account setup
- Artifact Registry test from a GCE VM
- Artifact Registry test from GKE (YAML via Cloud Deploy)
    - Optional steps on exposing the GKE service via GCLB + IAP (unrelated to Artifact Registry)
- Artifact Registry test from non-GKE cluster

The steps (till GCE VM and GKE) have been last tested and verified on a new Argolis project on Apr 6, 2022 (with 1 Org Policy change on restrictVpcPeering).
The "Access from Non-GKE Clusters" example requires key creation.

Reference: <https://cloud.google.com/artifact-registry/docs/docker/authentication>

## Variables

```bash

PROJECT_ID=$(gcloud config get-value project)
echo $PROJECT_ID
ORGANIZATION_ID=$(gcloud projects get-ancestors ${PROJECT_ID} --format="csv[no-heading](id,type)" | grep ",organization$" | cut -d"," -f1 )
echo ORGANIZATION_ID=$ORGANIZATION_ID

GCP_SERVICE_ACCOUNT="claims-sa"
CLOUD_DEPLOY_EXECUTION_SERVICE_ACCOUNT="cloud-deploy-runner"
# GCP_SERVICE_ACCOUNT="artifact-registry-reader"
REPOSITORY="docker-test"
# REPOSITORY="cloud-run-source-deploy"

NETWORK="default"
REGION="us-central1"
ZONE="${REGION}-a"

CLUSTER_NAME="pa-cluster"
```

## Enable APIs and Create NAT

```bash
gcloud services enable artifactregistry.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com clouddeploy.googleapis.com iap.googleapis.com

# org policies
# gcloud resource-manager org-policies allow compute.restrictVpcPeering  --project=$PROJECT_ID "under:organizations/$ORGANIZATION_ID" "under:organizations/433637338589"

REGIONS=( $REGION )

gcloud compute networks create ${NETWORK} --subnet-mode=auto


#gcloud compute firewall-rules create default-allow-ssh --network ${NETWORK} --priority=65534 --allow tcp:22
#gcloud compute firewall-rules create default-allow-rdp --network ${NETWORK} --priority=65534 --allow tcp:3389
#gcloud compute firewall-rules create default-allow-icmp --network ${NETWORK} --priority=65534 --allow icmp

gcloud compute firewall-rules create default-allow-internal --direction=INGRESS --priority=65534 --network=${NETWORK} --action=ALLOW --rules=all --source-ranges=10.128.0.0/9

for REGION in "${REGIONS[@]}"
do
    ( \
        gcloud compute routers create ${NETWORK}-router-${REGION} --network=$NETWORK --region ${REGION} && \
        gcloud compute routers nats create ${NETWORK}-nat-${REGION} --router=${NETWORK}-router-${REGION} --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --enable-logging --region ${REGION} \
    ) 
done

# IAP
gcloud compute firewall-rules create allow-iap --allow tcp:22,tcp:3389 --source-ranges=35.235.240.0/20 --network ${NETWORK}

```

## Create Repository

```bash

gcloud artifacts repositories create $REPOSITORY --repository-format=docker --location=$REGION

```

## Create Service Account to be used by GCE VM

```bash

gcloud iam service-accounts create "${GCP_SERVICE_ACCOUNT}" --project="${PROJECT_ID}"

# writer
# gcloud projects add-iam-policy-binding ${PROJECT_ID}  --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"

# reader
# gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.reader"

# or for individual repository
gcloud artifacts repositories add-iam-policy-binding $REPOSITORY --location=$REGION --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.reader"
gcloud artifacts repositories add-iam-policy-binding $REPOSITORY --location=$REGION --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"

# or editor for the project
# gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/editor"
```

## Optional - Create VM for testing

```bash

gcloud compute instances create test-vm --zone=${ZONE} \
  --machine-type=e2-micro \
  --no-address \
  --service-account="${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes="cloud-platform" \
  --image-family="debian-10" \
  --image-project="debian-cloud" \
  --shielded-secure-boot \
  --subnet="projects/$PROJECT_ID/regions/$REGION/subnetworks/$NETWORK"

gcloud compute ssh test-vm --zone=${ZONE}
```

## Optional - Artifact Registry Test within the VM

```bash
# Set up the region again

ZONE=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone")
REGION=$(echo $ZONE | sed -e "s/.*\///" -e "s/\(.*\)-.*/\1/")
echo REGION=$REGION

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg lsb-release -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

sudo groupadd docker
sudo usermod -aG docker ${USER}
# logout and login
# or do this
newgrp docker

docker pull hello-world


# Get the project id from within GCE VM
PROJECT_ID=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/project/project-id")
echo PROJECT_ID=$PROJECT_ID


docker tag hello-world ${REGION}-docker.pkg.dev/$PROJECT_ID/docker-test/hello-world


VERSION=2.1.0
OS=linux  # or "darwin" for OSX, "windows" for Windows.
ARCH=amd64  # or "386" for 32-bit OSs

curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${VERSION}/docker-credential-gcr_${OS}_${ARCH}-${VERSION}.tar.gz" | tar xz --to-stdout docker-credential-gcr | sudo tee /usr/bin/docker-credential-gcr >/dev/null

sudo chmod +x /usr/bin/docker-credential-gcr

docker-credential-gcr configure-docker --registries=${REGION}-docker.pkg.dev

# test
echo "https://${REGION}-docker.pkg.dev" | docker-credential-gcr get

docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/docker-test/hello-world

```

## Artifact Registry Access from GKE (tested with Cloud Deploy)

```bash
# Quite the VM and go back to your shell environment

gcloud container clusters create ${CLUSTER_NAME} \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --project=${PROJECT_ID} --zone=${ZONE} \
  --machine-type=e2-standard-4 --num-nodes=4 \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing \
  --enable-private-nodes --master-ipv4-cidr "172.16.0.0/28" --enable-master-global-access --enable-ip-alias \
  --no-enable-master-authorized-networks \
  --enable-shielded-nodes \
  --shielded-integrity-monitoring \
  --shielded-secure-boot \
  --service-account="${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"

# https://cloud.google.com/deploy/docs/deploy-app-gke

gcloud iam service-accounts create "${CLOUD_DEPLOY_EXECUTION_SERVICE_ACCOUNT}" --project="${PROJECT_ID}"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:"${CLOUD_DEPLOY_EXECUTION_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/clouddeploy.jobRunner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:"${CLOUD_DEPLOY_EXECUTION_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/container.developer"


docker pull nginx
docker tag nginx ${REGION}-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/nginx
# assuming docker-credential-gcr has been set up per above
docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/nginx

mkdir deploy-quickstart
cd deploy-quickstart

cat <<EOF > skaffold.yaml
apiVersion: skaffold/v2beta16
kind: Config
deploy:
  kubectl:
    manifests:
      - k8s-*
EOF

cat <<EOF > k8s-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: my-app-image
EOF

cat <<EOF > k8s-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: emr-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF

cat <<EOF > clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
 name: my-demo-app-1
description: main application pipeline
serialPipeline:
 stages:
 - targetId: $CLUSTER_NAME
   profiles: []
---

apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: $CLUSTER_NAME
description: development cluster
gke:
 cluster: projects/$PROJECT_ID/locations/${ZONE}/clusters/$CLUSTER_NAME
executionConfigs:
- defaultPool:
    serviceAccount: ${CLOUD_DEPLOY_EXECUTION_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com
  usages:
  - RENDER
  - DEPLOY
EOF

gcloud deploy apply --file clouddeploy.yaml --region=${REGION} 

gcloud deploy releases create test-release-$(date '+%Y%m%d-%H%M%S') \
  --region=${REGION} \
  --delivery-pipeline=my-demo-app-1 \
  --images=my-app-image=${REGION}-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/nginx

# quick test
kubectl port-forward svc/nginx-service 8080:80

```

## Optional - Expose the above K8s Service via GCLB Ingress + Identity-Aware Proxy

```bash

K8S_NAMESPACE=default
K8S_SERVICE=emr-service
K8S_SERVICE_PORT=80
K8S_SERVICE_HEALTHCHECK_PORT=80
K8S_INGRESS=${K8S_SERVICE}-ingress
K8S_INGRESS_IP_NAME=${K8S_SERVICE}-ip
K8S_BACKEND_CONFIG=${K8S_SERVICE}-backend-config
K8S_CERTIFICATE=${K8S_SERVICE}-certificate

FQDN="emr.endpoints.$PROJECT_ID.cloud.goog"

# firewall
gcloud compute firewall-rules create ${NETWORK}-allow-load-balancer-traffic-and-healthchecks \
    --allow tcp:${K8S_SERVICE_PORT} --source-ranges=35.191.0.0/16,130.211.0.0/22 \
    --network ${NETWORK} 
# ip
gcloud compute addresses create ${K8S_SERVICE}-ip --global
K8S_INGRESS_IP=$(gcloud compute addresses describe ${K8S_SERVICE}-ip --global --format="value(address)")
echo K8S_INGRESS_IP=$K8S_INGRESS_IP

# Map the FQDN to the IP address
cat <<EOF > ${K8S_SERVICE}-openapi.yaml
swagger: "2.0"
info:
  description: "$K8S_SERVICE"
  title: "$K8S_SERVICE"
  version: "1.0.0"
host: "${FQDN}"
x-google-endpoints:
- name: "${FQDN}"
  target: "$K8S_INGRESS_IP"
paths: {}

EOF

# ppaths: {}  /dummy:
#     get:
#       operationId: dummy
#       responses:
#         200:
#           description: OK
#       security:
#         - api_key: []
# securityDefinitions:
#   api_key:
#     type: "apiKey"
#     name: "key"
#     in: "query"

gcloud endpoints services deploy ${K8S_SERVICE}-openapi.yaml 
rm ${K8S_SERVICE}-openapi.yaml

cat <<EOF | kubectl apply -n $K8S_NAMESPACE -f -
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: ${K8S_CERTIFICATE}
spec:
  domains:
    - ${FQDN}
EOF

# IAP setup
BRAND_TITLE=emr-app
# Make sure the APIs are enabled (no harm re-running)
gcloud services enable iap.googleapis.com
# Retrieve the OAuth brand
BRAND_NAME=$(gcloud alpha iap oauth-brands list --format='value(name)')

# Create if it doesn't exist
if [ -z "$BRAND_NAME" ]
then
    # Create brand. support_email is required (it can be a group address)
    # This command provisions the brand as orgInternalOnly: true
    gcloud alpha iap oauth-brands create --application_title=${BRAND_TITLE} \
        --support_email=$(gcloud config get-value account) 
    BRAND_NAME=$(gcloud alpha iap oauth-brands list --format='value(name)')
fi

# Now create the OAuth Client
OAUTH_CLIENT=$(gcloud beta iap oauth-clients list ${BRAND_NAME} --filter='displayName=("'$BRAND_NAME'")' --format='value(name)')
if [ -z "$OAUTH_CLIENT" ]
then
  gcloud beta iap oauth-clients create ${BRAND_NAME} --display_name=${BRAND_NAME}
fi

# Retrieve the OAuth Client ID/Secret just to make sure they are working
read -r OAUTH_CLIENT_ID OAUTH_CLIENT_SECRET < <(gcloud beta iap oauth-clients list ${BRAND_NAME} --filter='displayName=("'$BRAND_NAME'")' --format='value(name,secret)')
OAUTH_CLIENT_ID=$(echo $OAUTH_CLIENT_ID | sed 's/.*\///' )

echo OAUTH_CLIENT_ID=$OAUTH_CLIENT_ID
echo OAUTH_CLIENT_SECRET=$OAUTH_CLIENT_SECRET

# kubectl delete secret ${K8S_SERVICE}-secret -n ${K8S_NAMESPACE}
kubectl create secret generic ${K8S_SERVICE}-secret -n ${K8S_NAMESPACE} --from-literal=client_id="$OAUTH_CLIENT_ID" --from-literal=client_secret="$OAUTH_CLIENT_SECRET"

# the backend config
cat <<EOF | kubectl apply -n $K8S_NAMESPACE -f -
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: ${K8S_BACKEND_CONFIG}
spec:
  iap:
    enabled: true
    oauthclientCredentials:
      secretName: ${K8S_SERVICE}-secret
EOF

kubectl patch svc $K8S_SERVICE -n $K8S_NAMESPACE -p '{"metadata": {"annotations": {"cloud.google.com/backend-config": "{\"default\": \"'${K8S_BACKEND_CONFIG}'\"}"}}}'

kubectl patch svc $K8S_SERVICE -n $K8S_NAMESPACE -p '{"metadata": {"annotations": {"cloud.google.com/backend-config": "{\"default\": \"'${K8S_BACKEND_CONFIG}'\"}"}}}'

# ingress
cat <<EOF | kubectl apply -n $K8S_NAMESPACE -f -
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: ${K8S_INGRESS}-frontend-config
spec:
  redirectToHttps:
    enabled: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${K8S_INGRESS}
  annotations:
    networking.gke.io/v1beta1.FrontendConfig: ${K8S_INGRESS}-frontend-config
    kubernetes.io/ingress.global-static-ip-name: ${K8S_INGRESS_IP_NAME}
    networking.gke.io/managed-certificates: ${K8S_CERTIFICATE}
    kubernetes.io/ingress.class: "gce"
spec:
  defaultBackend:
    service:
      name: ${K8S_SERVICE}
      port:
        number: ${K8S_SERVICE_PORT}
EOF

# add to the project level so that it doesn't get wiped out during backend re-creation
gcloud projects add-iam-policy-binding $PROJECT_ID --member="user:$(gcloud config get-value account)" --role="roles/iap.httpsResourceAccessor"

# the above ingress (GCLB, Certificate, etc) - ~30 minutes


```

## Optional - Artifact Registry Access from Non-GKE Clusters

<https://cloud.google.com/artifact-registry/docs/docker/authentication#json-key>

```bash

# create service account key
SECRET_ID="${GCP_SERVICE_ACCOUNT}-key"
gcloud services enable secretmanager.googleapis.com

# gcloud secrets delete $SECRET_ID
gcloud secrets create $SECRET_ID

# generate key and store it in secrets
gcloud iam service-accounts keys create /dev/stdout --iam-account="${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" | gcloud secrets versions add $SECRET_ID --data-file=-

# now add the docker secrets to Kubernetes
NAMESPACE="cloudrun-services"

# https://cloud.google.com/artifact-registry/docs/docker/authentication#json-key
kubectl create secret docker-registry "container-registry" \
  -n $NAMESPACE \
  --docker-server="https://${REGION}-docker.pkg.dev" \
  --docker-email="${GCP_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --docker-username="_json_key" \
  --docker-password="$(gcloud secrets versions access latest --secret=$SECRET_ID)"

kubectl patch serviceaccount default -n $NAMESPACE -p '{"imagePullSecrets": [{"name": "container-registry"}]}'

```
