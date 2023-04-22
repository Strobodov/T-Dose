#!/bin/bash

# source functions
source login.sh
source vm.sh
source containers.sh

# source variables
source .var

# login with Service Principal
loginServicePrincipal .spCred

# create VM
createVM

# open Network Security Group Port 80
openPort

# create Azure Container Registry
createACR

# build container image
buildContainer

# push container to Azure Container Registry
pushPodmanContainer

# configure VM
doVmStuff

# open browser to show result
firefox "${DNSNAME}.${LOCATION}.cloudapp.azure.com"