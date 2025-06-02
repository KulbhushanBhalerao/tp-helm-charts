## Azure specific variables
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv) # subscription id
export TP_TENANT_ID=$(az account show --query tenantId -o tsv) # tenant id
export TP_AZURE_REGION="eastus" # region of resource group
export TP_RESOURCE_GROUP="kul-atsbnl-flogo-azfunc"

## Cluster configuration specific variables
export TP_CLUSTER_NAME="aroRotterdamCluster"
export TP_WORKER_COUNT=6

## Network specific variables
export TP_VNET_NAME="openshiftRotterdamvnet"
export TP_MASTER_SUBNET_NAME="masterOpenshiftRotterdamSubnet"
export TP_WORKER_SUBNET_NAME="workerOpenshiftRotterdamSubnet"
export TP_VNET_CIDR="10.0.0.0/8"
export TP_MASTER_SUBNET_CIDR="10.17.0.0/23"
export TP_WORKER_SUBNET_CIDR="10.17.2.0/23"

## Worker Nodes specific configuration
export TP_WORKER_VM_SIZE="Standard_D8s_v5"
export TP_WORKER_VM_DISK_SIZE_GB="128"