#!/bin/bash
export SUBSCRIPTION=$(az account show --query id -o tsv)
export LOCATION="<INSERT LOCATION HERE>"
export HUB_RG="aro-hub"
export SPOKE_RG="aro-spoke"
export KEYVAULT_NAME="aro-kv"

az group create -n $HUB_RG -l $LOCATION
az group create -n $SPOKE_RG -l $LOCATION

export SP_NAME="<INSERT SERVICE PRINCIPAL NAME HERE>"
export APPID=$(az ad sp list --all --query "[?displayName == '$SP_NAME'].appId" -o tsv)

export SCOPE_HUB=$(az group create -n $HUB_RG -l $LOCATION --query id -o tsv)
export SCOPE_SPOKE=$(az group create -n $SPOKE_RG -l $LOCATION --query id -o tsv)

az role assignment create --assignee $APPID --role contributor --scope $SCOPE_HUB
az role assignment create --assignee $APPID --role contributor --scope $SCOPE_SPOKE
az role assignment create --assignee $APPID --role "User Access Administrator" --scope $SCOPE_SPOKE
az role assignment create --assignee $APPID --role "User Access Administrator" --scope $SCOPE_HUB
az keyvault purge -n $KEYVAULT_NAME