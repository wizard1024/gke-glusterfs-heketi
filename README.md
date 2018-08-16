# Hyper-converged GlusterFS and Heketi Dynamic Volume Provisioning on Google Container Engine (GKE)

## TL;DR

1. Edit [config](config) to match your GKE project/zone
2. Run init-cluster.sh <USER> <PASSWORD> (`./init-cluster.sh <USER> <PASSWORD>`)

## Usage by steps

1. Edit [config](config) to match your GKE project/zone
2. Source [helpers](helpers) (run `source helpers`)
3. Generate `k8s` (run `gke_glusterfs_heketi_generate_k8s`)
4. Create a cluster (run `gke_glusterfs_heketi_create_cluster` if you want)
5. Create namespace in cluster (run `kubectl create -f k8s/00-namespace.yaml`)
6. Add private registry credentials `kubectl -n glusterfs-heketi-bootstrap create secret docker-registry rtc-regcred --docker-server=registry.tymlez.com --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>`
7. Run `kubectl -n glusterfs-heketi-bootstrap create clusterrolebinding glusterfs-heketi-bootstrap --clusterrole=cluster-admin --user=system:serviceaccount:glusterfs-heketi-bootstrap:default --namespace=glusterfs-heketi-bootstrap` for deploy. 
8. Next create CLuster Role Binding for add capability to configure cluster (run `gcloud iam service-accounts list` and paste email as <EMAIL> to `kubectl create clusterrolebinding <EMAIL>-cluster-admin-binding --clusterrole=cluster-admin --user=<EMAIL>`)
9. Deploy `Job` within the cluster (run `gke_glusterfs_heketi_deploy_glusterfs_heketi`)
10. Wait for it to finish

You can deploy the example k8s (mariadb statefulset) to test that everything works.

1. `kubectl apply -f k8s-example`

### Tear down / Clean up

1. Run `gke_glusterfs_heketi_delete_cluster_and_disks`

## Installation flow

**NOTE:** All of this is automated. This is included purely for documentation purposes.

1. Create a cluster with at least 3 nodes
2. Create persistent disks and attach to the nodes
3. Load necessary kernel modules for GlusterFS, install `glusterfs-client` on host machines
4. Generate storage network topology
5. Create necessary firewall rules
6. Run `gk-deploy -g` to deploy the glusterfs daemonset and heketi
7. Change heketi service from `ClusterIP` to `NodePort` (will i/o timeout otherwise during persistent volume claim)
8. Update firewall rules to allow new heketi node port
9. Deploy heketi/glusterfs storage class using `<any node ip>:<heketi nodeport>`
