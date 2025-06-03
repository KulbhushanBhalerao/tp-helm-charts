# Azure Red Hat OpenShift (ARO) Cluster Operations

## Accessing the ARO API Server

```sh
az aro show --name ${TP_CLUSTER_NAME} --resource-group ${TP_RESOURCE_GROUP} --query "consoleProfile.url" -o tsv
```

Example API server URL:
```
https://api.yyx2iuc4.westeurope.aroapp.io:6443/
```

Login to the cluster:
```sh
oc login ${apiServer} -u kubeadmin -p <kubeadmin-password>
```

## Security Context Constraints (SCC)

Check the custom SCC:
```sh
oc get scc tp-scc
```

Example output:
```
NAME     PRIV    CAPS                   SELINUX     RUNASUSER   FSGROUP    SUPGROUP   PRIORITY   READONLYROOTFS   VOLUMES
tp-scc   false   ["NET_BIND_SERVICE"]   MustRunAs   RunAsAny    RunAsAny   RunAsAny   10         false            ["configMap","csi","downwardAPI","emptyDir","ephemeral","persistentVolumeClaim","projected","secret"]
```

Add `privileged` SCC to service accounts:
```sh
oc adm policy add-scc-to-user privileged -z default -n dp1
oc adm policy add-scc-to-user privileged -z sa -n dp1
```

## Ingress Information

List ingress classes:
```sh
oc get ingressclass -A
```

List ingress controllers and get domain:
```sh
oc get ingresscontroller -n openshift-ingress-operator default -o json | jq -r '.status.domain'
```

Example output:
```
apps.yyx2iuc4.westeurope.aroapp.io
```

## Troubleshooting: Azure Files StorageClass Provisioning

Example error:
```
failed to provision volume with StorageClass "azure-files-sc": rpc error: code = Internal desc = failed to ensure storage account: get private dns zone privatelink.file.core.windows.net returned with GET https://management.azure.com/... RESPONSE 403: 403 Forbidden ERROR CODE: AuthorizationFailed ...
```

### Solution: Set Resource Group Permissions

The ARO service principal requires `listKeys` permission on the Azure storage account resource group. Assign the Contributor role:

```sh
export ARO_RESOURCE_GROUP=kul-atsbnl-flogo-azfunc
export CLUSTER=aroCluster
ARO_SERVICE_PRINCIPAL_ID=$(az aro show -g $ARO_RESOURCE_GROUP -n $CLUSTER --query servicePrincipalProfile.clientId -o tsv)

az role assignment create --role Contributor --scope /subscriptions/<mySubscriptionID>/resourceGroups/$AZURE_FILES_RESOURCE_GROUP --assignee $ARO_SERVICE_PRINCIPAL_ID
```

### Solution: Set ARO Cluster Permissions

The OpenShift persistent volume binder service account requires permission to read secrets.

Login to the cluster:
```sh
ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)
oc login -u kubeadmin -p $(az aro list-credentials -g $ARO_RESOURCE_GROUP -n $CLUSTER --query=kubeadminPassword
