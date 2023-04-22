#!/bin/bash

#source generic functions
source generic.sh

# Variables used in this function:
# VMNAME
# GROUPNAME
# ADMIN
# depends on: .var

#create a VM in Azure
createVM(){

    #check if .var is present
    varFileCheck

    if ! az vm create \
            --name "$VMNAME" \
            --resource-group "$GROUPNAME" \
            --public-ip-address-dns-name "$DNSNAME" \
            --image "ubuntults" \
            --size "Standard_B1ls" \
            --generate-ssh-keys \
            --admin-username "$ADMIN" \
            --output none 2> /dev/null
    then
        printf "\r\e[31mERROR - LINE %s: failed to create Virtual Machine. \e[0m \n" "$LINENO"
        exit 1;
    else
        printf "\rcreating Virtual Machine = \e[32mOK \e[0m\n"
    fi
}

openPort(){
    
    #check if .var is present
    varFileCheck
    
    if ! az vm open-port \
            --resource-group "$GROUPNAME" \
            --name "$VMNAME" \
            --port 80 \
            --output none
    then
        printf "\r\e[31mERROR - LINE %s: failed to open port 80. \e[0m \n" "$LINENO"
        exit 1;
    else
        printf "\rOpening port 80 on NSG = \e[32mOK \e[0m\n"
    fi
}

doVmStuff(){
    local FQDN="${DNSNAME}.${LOCATION}.cloudapp.azure.com"
    local IMAGE_URL="${REGISTRYNAME}.azurecr.io/${IMAGENAME}:${IMAGETAG}"
    scp -o StrictHostKeyChecking=no .var "${ADMIN}@${FQDN}:~"
    ssh "${ADMIN}@${FQDN}" -o StrictHostKeyChecking=no 'bash -s' < server_config.sh \
        "$ACR_CRED" \
        "$IMAGE_URL" \
        "$REGISTRYNAME" \
        "$IMAGENAME" \
        "$IMAGETAG"
}