param (
    [Parameter(Mandatory)]
    [string]$subscriptionId,

    [Parameter(Mandatory)]
    [string]$resourceGroupName,

    [Parameter(Mandatory)]
    [string]$location,

    [Parameter(Mandatory)]
    [string]$clusterName,

    [Parameter(Mandatory)]
    [string]$role,

    [Parameter(Mandatory)]
    [string]$assignee,

    [Parameter(Mandatory)]
    [string]$yamlsPath
)

#set relevant subscription-id 
az account set --subscription $subscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Falied to set subscription-id = $subscriptionId"
}

#Create resoure group by name and location
az group create --name $resourceGroupName --location $location
if ($LASTEXITCODE -ne 0) {
    throw "Falied to create resource group $resourceGroupName at $location"
}

#create aks cluster with rbac and calico policy  -- node count is limited at my subscription, it can be changed
az aks create --name $clusterName --resource-group $resourceGroupName --node-count 2 --enable-azure-rbac --enable-aad --network-plugin azure --network-policy calico
if ($LASTEXITCODE -ne 0) {
    throw "Falied to create $clusterName cluster in group $resourceGroupName"
}

#get credentials and switch to aks cluster
az aks get-credentials --resource-group $resourceGroupName --name $clusterName   
if ($LASTEXITCODE -ne 0) {
    throw "Falied to get credential for cluster = $clusterName"
}

#assign role for the cluster
az role assignment create --role $role --scope /subscriptions/$subscriptionId  --assignee $assignee
if ($LASTEXITCODE -ne 0) {
    throw "Falied to assign $role role for assignee -> $assignee"
}

#create ingress namespace 
kubectl create namespace ingress-nginx
if ($LASTEXITCODE -ne 0) {
    throw "Falied to create namespace for ingress controller"
}

#install NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx --set controller.service.externalTrafficPolicy=Local
if ($LASTEXITCODE -ne 0) {
    throw "Falied to install nginx ingress controller"
}

#apply yaml files - directory with all the yamls
kubectl apply -f $yamlsPath
if ($LASTEXITCODE -ne 0) {
    throw "Falied to apply all desired yamls"
}

