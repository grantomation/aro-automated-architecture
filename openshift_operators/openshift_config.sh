#!/bin/bash

# USE MANAGED IDENTITY TO GET REQUIRED SECRETS
curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net&client_id=$IDENTITY" -H Metadata:true -s
TOKEN=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq -r '.access_token')
ARO_API=$(curl $KV_URI/secrets/aroApiServer/?api-version=2016-10-01 -H "Authorization: Bearer $TOKEN" | jq .value | tr -d '"')
ARO_KUBEADMIN_PWD=$(curl $KV_URI/secrets/aroKubeAdminPassword/?api-version=2016-10-01 -H "Authorization: Bearer $TOKEN" | jq .value | tr -d '"' )

# CONFIGURE OPENSHIFT AS KUBEADMIN

oc login -u kubeadmin -p $ARO_KUBEADMIN_PWD $ARO_API --insecure-skip-tls-verify

# Insert your configuration below;
# Please feel free to remove example applications

# Install web terminal operator
oc create -f web-terminal-operator.yaml

# Install sample web service from template
oc new-project sample-web-app
oc new-app --template httpd-example --name 'httpd' -n sample-web-app