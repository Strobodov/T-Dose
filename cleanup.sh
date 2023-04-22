#!/bin/bash

#get variables
source .var

#get IP address and/or FQDN from virtual server(s) to cleanup ~/.ssh/known_hosts
if [[ $(az network public-ip show --name "${VMNAME}PublicIP" --resource-group "$GROUPNAME" --query fqdn --output tsv) != "" ]]
then
    if ! FQDN=$(az network public-ip show \
                --name "${VMNAME}PublicIP" \
                --resource-group "$GROUPNAME" \
                --query fqdn \
                --output tsv)
    then
        printf "\r\e[31mERROR - LINE %s: getting FQDN failed. \e[0m \n" "$LINENO"
        exit 1;
    else   
        printf "\rgetting FQDN = \e[32mOK \e[0m \n"

        #check if FQDN exists in ~/.ssh/known_hosts
        if [[ $(ssh-keygen -qF "$FQDN") -eq "" ]]
        then
            printf "\r\e[33mWARNING: FQDN not found in known_hosts. \e[0m \n"
        else   
            printf "\rfinding FQDN in known_hosts = \e[32mOK \e[0m \n"
        fi
        #remove server(s) from ~/.ssh/known_hosts file based on FQDN
        if ! ssh-keygen -R "$FQDN" &> /dev/null
        then
            printf "\r\e[31mERROR - LINE %s: removing server from known_hosts file failed. \e[0m \n" "$LINENO"
            exit 1;
        else   
            printf "\rremoving server from known_hosts = \e[32mOK \e[0m \n"
        fi
    fi
else
    if ! VM_IP=$(az network public-ip show \
                --name "${VMNAME}PublicIP" \
                --resource-group "$GROUPNAME" \
                --query ipAddress \
                --output tsv)
    then
        printf "\r\e[33mWARNING - LINE %s: it seems there is no VM in resource group %s. \e[0m \n" "$LINENO" "$GROUPNAME"
    else   
        printf "\rgetting public IP address = \e[32mOK \e[0m \n"

        #check if public IP exists in ~/.ssh/known_hosts
        if [[ $(ssh-keygen -qF "$VM_IP") -eq "" ]]
        then
            printf "\r\e[33mWARNING: IP address not found in known_hosts. \e[0m \n"
        else   
            printf "\rfinding IP address in known_hosts = \e[32mOK \e[0m \n"
        fi
        #remove server(s) from ~/.ssh/known_hosts file based on public IP address
        if ! ssh-keygen -R "$VM_IP" &> /dev/null
        then
            printf "\r\e[31mERROR - LINE %s: removing server from known_hosts file failed. \e[0m \n" "$LINENO"
            exit 1;
        else   
            printf "\rremoving server from known_hosts = \e[32mOK \e[0m \n"
        fi
    fi
fi

#first delete VM('s), otherwise deleting disk resource will provide error
if ! az vm list --resource-group "$GROUPNAME" --query [].name --output tsv > virtual_machines
then
    printf "\r\e[31mERROR - LINE %s: getting virtual machine name(s) failed. \e[0m \n" "$LINENO"
    exit 1;
else   
    printf "\rgetting virtual machine name(s) = \e[32mOK \e[0m \n"
fi

while [[ $(wc -l virtual_machines | head -c 1) != 0 ]]
do
    while read -r LINE
    do
        if ! az vm delete \
            --name "$LINE" \
            --resource-group "$GROUPNAME" \
            --force-deletion "none" \
            --yes \
            --output none
        then
            printf "\r\e[31mERROR - LINE %s: deleting virtual machine failed. \e[0m \n" "$LINENO"
            exit 1;
        else
            printf "\rdeleting resource %s = \e[32mOK \e[0m \n" "$LINE"
            if ! az vm list --resource-group "$GROUPNAME" --query [].name --output tsv > virtual_machines.tmp
            then
                printf "\r\e[31mERROR - LINE %s: deleting virtual machine failed. \e[0m \n" "$LINENO"
                exit 1;
            else
                printf "\rdeleting virtual machine %s = \e[32mOK \e[0m \n" "$LINE"
            fi
        fi
    done < virtual_machines
    mv virtual_machines.tmp virtual_machines
done

#getting all resources in Resource Group
if ! az resource list --resource-group "$GROUPNAME" --query [].id --output tsv > resourceIDs
then
    printf "\r\e[31mERROR - LINE %s: getting resource ID's failed. \e[0m \n" "$LINENO"
    exit 1;
else   
    printf "\rgetting resource ID's = \e[32mOK \e[0m \n"
fi

while [[ $(wc -l resourceIDs | head -c 1) != 0 ]]
do
    while read -r LINE
    do
        if ! az resource delete --id "$LINE" --output none
        then
            printf "\r\e[31mERROR - LINE %s: deleting resources failed. \e[0m \n" "$LINENO"
            exit 1;
        else
            printf "\rdeleting resource %s = \e[32mOK \e[0m \n" "$LINE"
            if ! az resource list --resource-group "$GROUPNAME" --query [].id --output tsv > resourceIDs.tmp
            then
                printf "\r\e[31mERROR - LINE %s: deleting resources failed. \e[0m \n" "$LINENO"
                exit 1;
            else
                printf "\rrefreshing resource ID's = \e[32mOK \e[0m \n"
            fi
        fi
    done < resourceIDs
    mv resourceIDs.tmp resourceIDs
done

rm resourceIDs virtual_machines container_digest
printf "\rcleanup is done\041\n"