#!/bin/bash
az vm create \
    --name "t-dose" \
    --resource-group "T-Dose" \
    --admin-username "tdose" \
    --image "Ubuntu2204" \
    --public-ip-address-dns-name "tdose" \
    --size "Standard_b1ls" \
    --ssh-key-values ~/.ssh/id_rsa.pub
az vm open-port --resource-group "T-Dose" --name "t-dose" --port 80
ssh tdose@tdose.westeurope.cloudapp.azure.com -o StrictHostKeyChecking=no <<EOF
    sudo apt update
    sudo apt-get install docker.io --assume-yes
    git clone https://github.com/Strobodov/T-Dose.git
    sudo docker build T-Dose/App/ --tag=mywebapp
    sudo docker run -d -p 80:80 mywebapp
EOF
firefox http://tdose.westeurope.cloudapp.azure.com