#!/bin/bash

loginServicePrincipal(){

        #if .spCred and/or .azCred exists, read the credentials into a variable 
        #make everything readonly (to prevent from accidental change)
        if [[ "$1" == ".spCred" ]]
        then
            source ".spCred"
            readonly SP_APPID
            readonly SP_CERTNAME
            readonly TENANT_ID
            readonly SUBSCRIPTION
        else
            printf "\r\e[31mERROR - invalid filename used. \e[0m \n"
            return
        fi

    #login with service principal
    if ! az login --service-principal \
            --username "$SP_APPID" \
            --password "$SP_CERTNAME" \
            --tenant "$TENANT_ID" \
            --output none;
    then
        printf "\r\e[31mERROR - LINE %s: logging in as Service Principal failed. \e[0m \n" "$LINENO"
        exit 1;
    else   
        printf "\rlogging in as Service Principal = \e[32mOK \e[0m \n"
        #make sure you use the right subscription
        if ! az account set \
                --subscription "$SUBSCRIPTION"
        then
            printf "\r\e[31mERROR - LINE %s: setting subscription to %s failed. \e[0m \n" "$LINENO" "$SUBSCRIPTION"
            exit 1;
        else
            if [[ $(az account show --query name --output tsv) -eq "$SUBSCRIPTION" ]]
            then
                printf "\rsetting subscription to %s = \e[32mOK \e[0m \n" "$SUBSCRIPTION"
            else
                printf "\r\e[31mERROR - LINE %s: subscription has changed, but not to the desired value. \e[0m \n" "$LINENO"
                exit 1;
            fi
        fi
    fi
}
