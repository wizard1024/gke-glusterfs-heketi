#!/bin/bash

# https://cloud.google.com/compute/docs/machine-types

# --------------------- [START] Create Kubernetes cluster -------------------- #
echo ""
echo " ====================== [START] Creating Kubernetes cluster ======================= "
echo ""
echo "      CLOUDSDK_PROJECT_NAME: $project_name"
echo "      CLOUDSDK_CLUSTER_NAME: $cluster_name"
echo "      CLOUDSDK_COMPUTE_ZONE: $zone"
echo "      CLOUDSDK_COMPUTE_NET:  $subnet"
echo "      CLUSTER_VERSION:       $cluster_version"
echo "      NODE_COUNT:            $node_count"
echo "      MACHINE_TYPE:          $machine_type"
echo "      CLUSTER_IP_CIDR:       $cluster_ip_cidr"
echo ""

# Check cluster Ip
for i in $(gcloud container clusters list | grep -v NAME | cut -f1 -d " ")
do
	IP=$(gcloud container clusters describe $i | grep clusterIpv4Cidr: | head -n 1 | cut -d " " -f 2)
	if [ "$IP" == "$cluster_ip_cidr" ]; then
		echo "Error: CLUSTER_IP_CIDR should be unique accross clusters in project and/or accross clusters in all project (for network peering)"
		exit 1
	fi
done

# gcloud container --project "$PROJECT_ID" clusters create "$CLUSTER_NAME" --cluster-version "$CLUSTER_VERSION" --quiet \
cluster_version_option=''
if [ ! -z "$cluster_version" ]
then
  cluster_version_option="--cluster-version $cluster_version"
fi

gcloud beta compute networks subnets update $subnet --add-secondary-ranges pods-$cluster_name=$cluster_ip_cidr,services-$cluster_name=$cluster_ip_services

gcloud container --project "$project_name" clusters create "$cluster_name" $cluster_version_option \
    --zone "$zone" \
    --machine-type "$machine_type" \
    --network "$network" \
    --subnetwork "$subnet" \
    --image-type=ubuntu \
    --enable-ip-alias \
    --disk-size '200' \
    --cluster-secondary-range-name=pods-$cluster_name \
    --services-secondary-range-name=services-$cluster_name \
    --enable-cloud-endpoints \
    --num-nodes "$node_count" \
    --no-enable-cloud-logging 

echo ""
echo " ======================= [END] Creating Kubernetes cluster ======================== "
echo ""

# Set context to new cluster
gcloud container clusters get-credentials "$cluster_name" --zone "$zone" --project "$project_name"
# ---------------------- [END] Create Kubernetes cluster --------------------- #

# --------------------- [START] Modify ssh firewall rule -------------------- #
firewall_ssh_rule=$(gcloud compute firewall-rules list --filter="network" --format="table(name)" | grep ssh | grep $cluster_name)
sr=$(gcloud compute firewall-rules describe $firewall_ssh_rule --format="csv[no-heading,delimiter=','](sourceRanges)")
myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
gcloud compute firewall-rules update "$firewall_ssh_rule" \
       --allow "tcp:22" \
       --source-ranges="${sr},${myip}/32"
# --------------------- [END] Modify ssh firewall rule -------------------- #


# --------------------- [START] Add packages -------------------- #
for node in $(kubectl get nodes -o name)
do
  node=$(basename $node)

  echo ""
  echo " ======================== [START] Configuring $node software-properties-common ======================== "
  echo ""

  gcloud compute --project "$project_name" ssh "$node" \
    --zone "$zone" \
    --command "\
      sudo sh -c '\
        apt-get update && apt-get install software-properties-common -y \
        '"
  echo ""
  echo " ========================= [END] Configuring $node ========================= "
  echo ""
done
# ---------------------- [END] Add packages --------------------- #
