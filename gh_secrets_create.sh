
#!/bin/bash
export REPOSITORY="<USER/REPOSITORY>"
export LOCATION="<DESIRED ARO LOCATION>"
export HUB_RG="aro-hub"
export SPOKE_RG="aro-spoke"
export SP_NAME="<INSERT SERVICE PRINCIPAL NAME HERE>"

#Set the github repo
gh secret list -R $REPOSITORY

export JUMPBOX_ADMIN_USER="<INSERT VALUE HERE>"
export JUMPBOX_ADMIN_PWD="<INSERT VALUE HERE>"

export TENANT_ID=$(az account list --query "[?name =='Cloud Services Black Belt Subscription'].tenantId" -o tsv)
export AZURE_SUBSCRIPTION=$(az account show --query id -o tsv)
export AZURE_CREDENTIALS=$(cat sp.txt)
export AAD_CLIENT_ID=$(az ad sp list --all --query "[?displayName == '$SP_NAME'].appId" -o tsv)
export AAD_CLIENT_SECRET=$(cat sp.txt | jq -r .clientSecret)
export AAD_OBJECT_ID=$(az ad sp show --id $AAD_CLIENT_ID --query id -o tsv)
export ARO_RP_OB_ID=$(az ad sp list --all --query "[?appDisplayName=='Azure Red Hat OpenShift RP'].id" -o tsv)
export PULL_SECRET=$(cat pull-secret.json | sed 's/"/\\"/g')

gh secret set AZURE_SUBSCRIPTION --body "$AZURE_SUBSCRIPTION" -R $REPOSITORY
gh secret set AZURE_CREDENTIALS --body "$AZURE_CREDENTIALS" -R $REPOSITORY
gh secret set AAD_CLIENT_ID --body "$AAD_CLIENT_ID" -R $REPOSITORY
gh secret set AAD_CLIENT_SECRET --body "$AAD_CLIENT_SECRET" -R $REPOSITORY 
gh secret set AAD_OBJECT_ID --body "$AAD_OBJECT_ID" -R $REPOSITORY
gh secret set ARO_RP_OB_ID --body "$ARO_RP_OB_ID" -R $REPOSITORY
gh secret set JUMPBOX_ADMIN_USER --body "$JUMPBOX_ADMIN_USER" -R $REPOSITORY
gh secret set JUMPBOX_ADMIN_PWD --body "$JUMPBOX_ADMIN_PWD" -R $REPOSITORY
gh secret set SPOKE_RG --body "$SPOKE_RG" -R $REPOSITORY
gh secret set HUB_RG --body "$HUB_RG" -R $REPOSITORY
gh secret set PULL_SECRET --body "$PULL_SECRET" -R $REPOSITORY