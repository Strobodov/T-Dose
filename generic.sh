#!/bin/bash

#check if required .var file is present in the current working directory
varFileCheck(){
    local FILECHECK=0

    while [[ $FILECHECK = 0 ]]
    do
        if [[ ! -f .var ]]
        then
            printf "\r\e[1;33mWARNING: .var file is (still) missing. Please create it. \e[0m \n"
            printf "\rWaiting for .var file to be added...."
            sleep 5
        else
            printf "\r.var file check = \e[32mOK \e[0m \n"
            if ! source .var
            then
                printf "\r\e[31mERROR - LINE %s: failed to source .var file. \e[0m \n" "$LINENO"
                exit 1;
            else
                printf "\rsourcing .var = \e[32mOK \e[0m\n"
                FILECHECK=1
            fi
        fi
    done
}