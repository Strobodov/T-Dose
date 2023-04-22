#!/bin/bash

#source generic functions
source generic.sh

# Variables used in this function:
# REGISTRYNAME
# GROUPNAME
# LOCATION
# depends on: .var

createACR(){

    #check if .var is present
    varFileCheck

    if ! az acr create \
        --name "$REGISTRYNAME" \
        --resource-group "$GROUPNAME" \
        --sku "Standard" \
        --location "$LOCATION" \
        --zone-redundancy Disabled \
        --output none 2> /dev/null
    then
        printf "\r\e[31mERROR - LINE %s: failed to create ACR. \e[0m \n" "$LINENO"
        exit 1;
    else
        if [[ "$(az acr show --name "$REGISTRYNAME" --query provisioningState --output tsv)" = "Succeeded" ]]
        then
            printf "\rACR provisioning = \e[32mOK \e[0m\n"
        else
            printf "\r\e[31mERROR - LINE %s: ACR provisioning failed. \e[0m \n" "$LINENO"
            exit 1;
        fi
    fi

    #enable admin account
    if ! az acr update \
        --name "$REGISTRYNAME" \
        --admin-enabled true \
        --anonymous-pull-enabled false \
        --output none
    then
        printf "\r\e[31mERROR - LINE %s: command to update ACR failed. \e[0m \n" "$LINENO"
        exit 1;
    else
        if [[ "$(az acr show \
                --name "$REGISTRYNAME" \
                --query adminUserEnabled \
                --output tsv)" = "true" ]] && [[ "$(az acr show \
                                                    --name "$REGISTRYNAME" \
                                                    --query anonymousPullEnabled \
                                                    --output tsv)" = "false" ]]
        then
            printf "\rACR update = \e[32mOK \e[0m\n"
        else
            printf "\r\e[31mERROR - LINE %s: updating ACR failed. \e[0m \n" "$LINENO"
            exit 1; 
        fi
    fi

    #get registry credentials for pushing containers and create shell variable
    if ! ACR_CRED=$(az acr credential show \
        --name "$REGISTRYNAME" \
        --query passwords[0].value \
        --output tsv)
    then
        printf "\r\e[31mERROR - LINE %s: failed to get ACR credentials. \e[0m \n" "$LINENO"
        exit 1;
    else
        printf "\rgetting ACR credentials = \e[32mOK \e[0m\n"
    fi
    readonly ACR_CRED
}

#build the container locally using Podman
# Variables used in this function:
# IMAGENAME
# IMAGETAG
# depends on: .var
buildContainer(){

    #check if .var is present
    varFileCheck

    if ! IMAGE_ID=$(podman build \
            --tag "${IMAGENAME}:${IMAGETAG}" \
            "$PWD/App" \
            --no-cache \
            --quiet)
    then
        printf "\r \e[31mERROR LINE %s\e[0m: building container image failed.\n" "$LINENO"
        exit 1;
    else
        printf "\r Building container image = \e[32mok\e[0m\n"
    fi
}

# Check the sha256 digest of container images (integrity check)
# Variables used in this function:
# IMAGENAME
# IMAGETAG
# REGISTRYNAME
# depends on: .var

checkContainerDigest(){
    
    #check Azure container digest
    local AZURE_DIGEST=$(az acr repository show \
    --name "$REGISTRYNAME" \
    --image "${IMAGENAME}:${IMAGETAG}" \
    --query "digest" \
    --output tsv)

    #get local digest that is created by podman and check if it matches with the digest in Azure
    local LOCAL_DIGEST=$(cat container_digest)
    
    #do the actual check...
    if [[ "$LOCAL_DIGEST" = "$AZURE_DIGEST" ]]
    then
        printf "\r \e[32mSUCCESS\e[0m: Digests match.\n"
    else 
        printf "\r \e[33mWARNING\e[0m: Digests are different.\n"
    fi
}

# Variables used in this function:
# IMAGE_ID
# REGISTRYNAME
# IMAGENAME
# IMAGETAG
# ACR_CRED
# depends on: .var

pushPodmanContainer(){
    
    #check if .var is present
    varFileCheck

    if ! podman push \
            "$IMAGE_ID" \
            "${REGISTRYNAME}.azurecr.io/${IMAGENAME}:${IMAGETAG}" \
            --creds "${REGISTRYNAME}:${ACR_CRED}" \
            --tls-verify \
            --digestfile container_digest
    then
        printf "\r \e[31mERROR LINE %s\e[0m: pushing container to ACR failed.\n" "$LINENO"
        exit 1;
    else
        if [[ $(az acr repository show \
                    --name "$REGISTRYNAME" \
                    --image "${IMAGENAME}:${IMAGETAG}" \
                    --query changeableAttributes.listEnabled \
                    --output tsv) = "true" ]]
        then
            printf "\r container push = \e[32mok\e[0m\n"
        else
            printf "\r \e[31mERROR LINE %s\e[0m: pushing container to ACR failed. \
                    Container does not seem to be in the repository.\n" "$LINENO"
            exit 1;
        fi
    fi
    checkContainerDigest
}

