#!/usr/bin/env bash

# To Be Provisioned by DTP
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR"/vars

while getopts p:c: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        c) CLUSTER=${OPTARG};;
        *)
    esac
done

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}

setup_network(){
  network=$(gcloud compute networks list --filter="name=( $NETWORK )" --format='get(NAME)' 2>/dev/null)
  if [ -z "$network" ]; then
      echo "Setting up [$NETWORK] network... "
      gcloud compute networks create "$NETWORK" --project="$PROJECT_ID" \
      --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional
      gcloud compute firewall-rules create default-allow-internal-"$NETWORK" --project="$PROJECT_ID" \
            --network=projects/"$PROJECT_ID"/global/networks/"$NETWORK" \
            --description=Allows\ connections\ from\ any\ source\ in\ the\ network\ IP\ range\ to\ any\ instance\ on\ the\ network\ using\ all\ protocols. \
            --direction=INGRESS --priority=65534 --source-ranges=10.128.0.0/9 --action=ALLOW --rules=all
  fi
}

create_cluster_autopilot(){
  echo "Creating GKE Autopilot...[$CLUSTER]"

  if [[ $ARGOLIS == 'true' ]]; then
    echo "Disabling constraints for Argolis ..."
    gcloud org-policies reset constraints/compute.vmExternalIpAccess --project $PROJECT_ID
  fi
  gcloud container clusters create-auto "$CLUSTER" \
      --region "$REGION" \
      --network "$NETWORK" \
      --project="$PROJECT_ID"
}

create_cluster_gke() {
  echo "Creating GKE Cluster [$CLUSTER]..."

  if [[ $ARGOLIS == 'true' ]]; then
    gcloud org-policies reset  constraints/compute.requireShieldedVm --project $PROJECT_ID
    gcloud org-policies reset  constraints/compute.requireOsLogin --project $PROJECT_ID
  fi

  gcloud beta container --project "$PROJECT_ID" clusters create "$CLUSTER" --zone "$ZONE"\
   --no-enable-basic-auth --cluster-version "$CLUSTER_VERSION" --release-channel "regular" \
   --machine-type "$MACHINE_TYPE" --image-type "COS_CONTAINERD" --disk-type "pd-standard" \
   --disk-size "200" --metadata disable-legacy-endpoints=true \
    --max-pods-per-node "110" --num-nodes "4" --max-nodes "8"\
    --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias \
    --network "projects/$PROJECT_ID/global/networks/$NETWORK" \
    --subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/$NETWORK" \
    --no-enable-intra-node-visibility --default-max-pods-per-node "110" \
    --no-enable-master-authorized-networks \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver,Istio \
    --enable-autoupgrade --enable-autorepair  --enable-autoscaling  \
    --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
    --workload-pool "$PROJECT_ID.svc.id.goog" \
    --enable-shielded-nodes --node-locations "$ZONE"
}

setup_cluster() {
  echo "Setting up [$CLUSTER] cluster..."
  RESULT="$(gcloud container clusters list --region="$REGION" --format="value(name)" --project "$PROJECT_ID" --filter="name=${CLUSTER}" || true)"
  if [[ -n "${RESULT}" ]]; then
    echo "Cluster [$CLUSTER] already up and running in [$REGION]"
  else
    echo "Creating  [$CLUSTER] cluster in [$REGION] region..."

    if [ -n "$EXPERIMENTAL" ]; then
      create_cluster_gke
    else
      create_cluster_autopilot
    fi
  fi

  #gcloud container clusters create CLUSTER --workload-pool=PROJECT_ID.svc.id.goog
  gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"
}

setup_network

setup_cluster

