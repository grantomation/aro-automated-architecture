Deploying Azure Red Hat OpenShift (ARO) is a fairly straightforward process. By following the [official documentation](https://docs.microsoft.com/en-au/azure/openshift/intro-openshift), creating the required Azure infrastructure and running the deployment command, a highly available OpenShift cluster will become available and ready to run containerised workloads in approximately 30 minutes.

Integrating ARO into existing Azure enterprise architectures can take a little more time, as networking, routing and traffic rules need to be created. Inspired by the [ARO reference architecture](https://github.com/UmarMohamedUsman/aro-reference-architecture), this repo contains bicep modules which will deploy ARO and other common resources found in enterprise Azure environments using a consistent, repeatable deployment method and will take approximately 45 minutes to complete. 

# Architecture
- 2 resource groups forming hub/spoke architecture. Networking resources within these resource groups are peered. 

    1. A Spoke resource group will contain the private Azure Red Hat OpenShift and associated networking requirements
    1. Hub resource group will contain Azure native services commonly seen in enterprise architectures
        - Azure Firewall
            - Firewall rules default to permit application traffic described in the [restrict egress traffic documentation](https://docs.microsoft.com/en-au/azure/openshift/howto-restrict-egress). These can be configured to be more restrictive in the firewall module found at `./modules/firewall.bicep`.
        - Azure Bastion Service
        - A virtual machine to be used as a jumpbox into the private network. 
            - A custom script extension (cse) is used by the jumpbox deployment to configure software for interacting with OpenShift. This cse is external to this repo and can be [found here](https://github.com/grantomation/aro-cse).

# Deployment Methods

1. Run the bicep modules in a github actions pipeline.

![Github actions pipeline](./images/github_actions.png)

# Github actions deployment 

Using the github actions workflow the bicep modules can be deployed from a github repo. The github actions deployment will be scoped to the resource group level. This means that there will initally be a additional steps to create a service principal, resource groups and assign the appropriate permissions. These steps will only have to be run once for as long as the resource groups and service principal remain within the Azure environment. The github actions workflow will use public runners unless otherwise configured.

> :warning: Please be careful about how you store secrets. It is advised to use a private repo to ensure that there is a less chance of private data exposure.

## Github actions prerequisites

### Create resource groups

> :warning: Try not to delete the resource groups once created or you will need to run the permissions commands again.

As a user run the following command to create resource groups that will be used for the github actions deployment.

```
$ export SUBSCRIPTION=$(az account show --query id -o tsv)
$ export LOCATION=<insert location here>
$ export HUB_RG="<insert hub resource group name here>"
$ export SPOKE_RG="<insert spoke resource group name here>"

$ az group create -n $HUB_RG -l $LOCATION
$ az group create -n $SPOKE_RG -l $LOCATION

```
### Create a service principal

Create a service principal that will run the github actions bicep modules. This SP will also be granted "User access admin" permission on the spoke resource group, this is to ensure that the ARO deployment can assign the resource provider "Red Hat OpenShift RP" permissions to the spoke resource group.

```
$ export SP_NAME="<insert name for the service principal here>"

$ az ad sp create-for-rbac -n $SP_NAME --role contributor --sdk-auth --scopes "/subscriptions/$SUBSCRIPTION/resourceGroups/$SPOKE_RG" > sp.txt

$ export AAD_CLIENT_ID=$(az ad sp list --all --query "[?displayName == '$SP_NAME'].appId" -o tsv)

```

### Scope the service principal's permissions to the hub and spoke resource groups

```
$ export SCOPE_HUB=$(az group create -n $HUB_RG -l $LOCATION --query id -o tsv)
$ export SCOPE_SPOKE=$(az group create -n $SPOKE_RG -l $LOCATION --query id -o tsv)


$ az role assignment create --assignee $AAD_CLIENT_ID --role contributor --scope $SCOPE_HUB
$ az role assignment create --assignee $AAD_CLIENT_ID --role contributor --scope $SCOPE_SPOKE
$ az role assignment create --assignee $AAD_CLIENT_ID --role "User Access Administrator" --scope $SCOPE_SPOKE

```

### Modify parameter

1. Modify the parameters found in `./action_params/*.json` to suit your environment.

1. Modify the parameters found in `./github/workflows/action_deploy_aro_enterprise.yml` to suit your environment.
    * LOCATION (location for resources)
    * HUB_VNET (name of the hub vnet)
    * SPOKE_VNET (name of the spoke vnet)
    * FW_PRIVATE_IP (private IP of the Azure firewall - defaults to 10.0.0.4)
    * ROUTE_TABLE_NAME (name of the route table), and,
    * CLUSTER_NAME (the name of the ARO cluster)

### Create github encrypted secrets to be used by github actions

The following secrets will need to be created in the github repository as "Action Secrets". Go to your repo > select settings > select secrets > select Actions > select "New repository secret".

| Secret Name | Command to run to get correct value for secret | 
| --- | --- | 
| AZURE_SUBSCRIPTION | ` az account show --query id -o tsv ` | 
| AZURE_CREDENTIALS | copy the contents of sp.txt here. Json format will work | 
| AAD_CLIENT_ID | `az ad sp list --all --query "[?displayName == '$SP_NAME'].appId" -o tsv` |
| AAD_CLIENT_SECRET | `cat sp.txt \| jq -r .clientSecret ` | 
| AAD_OBJECT_ID | `az ad sp show --id $AAD_CLIENT_ID --query id -o tsv`  |
| ARO_RP_OB_ID | `az ad sp list --all --query "[?appDisplayName=='Azure Red Hat OpenShift RP'].id" -o tsv` |
| JUMPBOX_ADMIN_USER | \<insert the name of the windows user for the jumpbox\> | 
| JUMPBOX_ADMIN_PWD | \<insert the password for the jumpbox\> | 
| SPOKE_RG | \<insert the spoke resource group name\> | 
| HUB_RG | \<insert the hub resource group name\> |
| PULL_SECRET | Format the Red Hat Pull Secret with the following command `cat pull-secret.json \| sed 's/"/\\"/g'` then place the output into the secret

> :Note: The pull secret should have the following syntax prior to adding it to the github secret `{\"auths\":{\"cloud.openshift.com\":{\"auth\":\"XXXXXXXXXX\" ...`


## Github actions Deployment

To run the github actions to deploy the environment select the following;

![Run ARO github action](./images/run_aro_action.png)

## Github actions Cleanup

To run the github actions to deploy the environment select the following;

![Cleanup ARO resources](./images/cleanup_action.png)

# Upcoming Features
* Day 2 - Integrate Azure Active Directory for OpenShift login
* Day 2 - Deploy an application to OpenShift
* Day 2 - Configure useful OpenShift operators
* Configure Azure logging integration
* Learn more about Bicep, Azure and Github actions and continuously improve the code

# **Pull Requests are welcome!**