#!/bin/bash
export SUBSCRIPTION=$(az account show --query id -o tsv)
export LOCATION="<INSERT LOCATION HERE>"
export HUB_RG="aro-hub"
export SPOKE_RG="aro-spoke"
export KEYVAULT_NAME="aro-kv"

az group delete -n $HUB_RG -y
az group delete -n $SPOKE_RG -y
az keyvault purge -n $KEYVAULT_NAME