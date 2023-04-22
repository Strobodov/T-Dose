#!/bin/bash

#source the .var file
source .var

#update package index
sudo apt update

#install podman
sudo apt-get install docker.io --assume-yes

#login docker
printf "%s" "$1" | sudo docker login --password-stdin --username "$3" "${3}.azurecr.io"

#pull container from Azure Container Registry
sudo docker pull "$2"

#run container, detached on port 80
sudo docker run -dp 80:80 "$2"