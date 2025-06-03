#!/bin/bash

# -----------------------------------------------------------------------------
# Azure Red Hat OpenShift (ARO) Environment Variables and Setup
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Azure Specific Variables
# -----------------------------------------------------------------------------
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv)           # Subscription ID
export TP_TENANT_ID=$(az account show --query tenantId -o tsv)           # Tenant ID
export TP_AZURE_REGION="westeurope"                                      # Azure Region
export TP_RESOURCE_GROUP="kul-atsbnl-flogo-azfunc"                       # Resource Group

# -----------------------------------------------------------------------------
# Cluster Configuration Variables
# -----------------------------------------------------------------------------
export TP_CLUSTER_NAME="aroCluster"
export TP_WORKER_COUNT=6

# -----------------------------------------------------------------------------
# Network Configuration Variables
# -----------------------------------------------------------------------------
export TP_VNET_NAME="openshiftvnet"
export TP_MASTER_SUBNET_NAME="masterOpenshiftSubnet"
export TP_WORKER_SUBNET_NAME="workerOpenshiftSubnet"
export TP_VNET_CIDR="10.0.0.0/8"
export TP_MASTER_SUBNET_CIDR="10.17.0.0/23"
export TP_WORKER_SUBNET_CIDR="10.17.2.0/23"

# -----------------------------------------------------------------------------
# Worker Node Configuration
# -----------------------------------------------------------------------------
export TP_WORKER_VM_SIZE="Standard_D8s_v5"
export TP_WORKER_VM_DISK_SIZE_GB="128"

# -----------------------------------------------------------------------------
# Tooling Variables
# -----------------------------------------------------------------------------
export TP_TIBCO_HELM_CHART_REPO="https://tibcosoftware.github.io/tp-helm-charts"

# -----------------------------------------------------------------------------
# Resource Group and Cluster Variables
# -----------------------------------------------------------------------------
export ARO_RESOURCE_GROUP="$TP_RESOURCE_GROUP"
export CLUSTER="$TP_CLUSTER_NAME"
export AZURE_FILES_RESOURCE_GROUP="$TP_RESOURCE_GROUP"

# -----------------------------------------------------------------------------
# Set Resource Group Permissions
# -----------------------------------------------------------------------------
# The ARO service principal requires listKeys permission on the new Azure storage account resource group.
# Assign the Contributor role.

ARO_SERVICE_PRINCIPAL_ID=$(az aro show -g "$ARO_RESOURCE_GROUP" -n "$CLUSTER" --query servicePrincipalProfile.clientId -o tsv)

az role assignment create \
  --role Contributor \
  --scope "/subscriptions/$TP_SUBSCRIPTION_ID/resourceGroups/$AZURE_FILES_RESOURCE_GROUP" \
  --assignee "$ARO_SERVICE_PRINCIPAL_ID"

# -----------------------------------------------------------------------------
# Set ARO Cluster Permissions
# -----------------------------------------------------------------------------
# The OpenShift persistent volume binder service account requires the ability to read secrets.
# Create and assign an OpenShift cluster role.

ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)

oc login -u kubeadmin -p "$(az aro list-credentials -g "$ARO_RESOURCE_GROUP" -n "$CLUSTER" --query=kubeadminPassword -o tsv)" "$ARO_API_SERVER"

oc create clusterrole azure-secret-reader \
  --verb=create,get \
  --resource=secrets

oc adm policy add-cluster-role-to-user azure-secret-reader system:serviceaccount:kube-system:persistent-volume-binder