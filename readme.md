# Reproduction 502 errors 


## Prereqs for installation

* Azure CLI
* kubectl
* helm
* jmeter


## Installation

First you need to create the Azure Resources:
```
az account set -s <target subscription>
cd terraform
terraform apply
```

Next you can deploy the AKS resources:
```
az aks get-credentials -n aks-repro-502 -g repro-502
cd ../aks
./deploy-aks-resources.sh
```

Wait until the Application Gateway backend healt turn green (can take up to 15 minutes). After that you can start a load test:

```
cd ../jmeter
./jmeter -n -t repro-502.jmx -f -l results.log -Jfrontend_protocol=http -Jbackend_protocol=https -Jip_address=$(az network public-ip show -n pip-agw -g repro-502 --query ipAddress -o tsv)
```
