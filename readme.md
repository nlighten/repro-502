# Reproduction 502 errors 
This repo contains a reproduction scenario for 502 errors observed using AKS.

## Prereqs for installation

* Azure CLI
* kubectl
* helm
* jmeter 5.6.x


## Installation
### Step 1: create Azure resources

First you need to create the Azure resources using Terraform:
```
az account set -s <target subscription>
cd terraform
terraform apply
```

By default this will create an AKS cluster with a separate system and user pool with the `Standard_D4s_v5` sku, `Managed` disks and `kubenet` network plugin. Optionally you can specify the following variables during `terraform apply` to change the cluster type:

| variable | description|
|----|----|
|vm_sku|Sku for aks cluster VM's. For symplicity sake user and system pools use the same sku.|
|vm_disk_type|Disk type for AKS cluster VM's. Allowed values are `Managed` and, if the sku type supports it `Ephemeral`|
|aks_network_plugin|AKS network plugin. Allowed values are `kubenet` and `azure`|



### Step 2: deploy AKS resources
Next you can deploy the AKS resources:
```
az aks get-credentials -n aks-repro-502 -g repro-502
cd ../aks
./deploy-aks-resources.sh
```

### Step 3: Manually update Application Gateway
One of the scenario's we will be testing is a direct connection between Application Gateway and the AKS cluster, so without Azure Load Balancer in between. For this we need to manualle configure the Service ports that where randomly selected during deployment. First you need to list the ingress-nginx service to find the `http` and `https` ports used:

```
kubectl get service -n ingress-nginx
```

Update the Application Gateway Backend Settings named `aks-http-direct` and `aks-https-direct` with the ports used by the service. After this is done wait until all backends turn green on the Backend health page (can take up to 15 minutes). After that you can start one of the supported test scenario's.



## Testing

Before you start testing it is recommended to change the following properties in the `jmeter.properties` file. This throttles the bandwith and results in our tests in a relatively predictably 35-40 transactions per second and good reproduction of the issues.

```
httpclient.socket.http.cps=128000
httpclient.socket.https.cps=128000
```

The jmeter script supports a number of parameters to vary the scenario's:


| parameter | default | description|
|----|----| ----|
|threads| `20` | Number of threads (concurrent 'users).|
|ramp_up| `10` | Ramp up period in seconds|
|loop_count| `5000` | Number of loops per thread |
|frontend_protocol| `http` | Protocol used to connect to the Application Gateway. Current setup only supports `http` since no certificate is configured on the Application Gateway |
|backend_protocol| `https`| Protocol used between Application Gateway and Nginx ingress running on AKS cluster. |
|backend_type| `lb` | Determines if Azure Load Balancer is used between Application Gateway and Nginx ingress. Allowed values are `lb` and `direct`.|


Example command line:

```
cd ../jmeter
./jmeter -n -t repro-502.jmx -f -l results.log -Jbackend_type=lb -Jbackend_protocol=https -Jip_address=$(az network public-ip show -n pip-agw -g repro-502 --query ipAddress -o tsv)
```

After starting the test you can monitor the `results.log` on errors:

```
tail -f results.log | grep -v OK
```


## Tested scenario's
So far we tested the following scenario's:

|Sku | Netork Plugin | Disk Type |Backend Protocol | Backend Type | Result | Other | Comment |
|----|---------------|-----------|-----------------|--------------|--------|-------|---------|
|Standard_D4s_v5| kubenet | Managed|https| lb | - | NOK | `502 Bad Gateway` and `org.apache.http.ConnectionClosedException` errors |
|Standard_D4s_v5| kubenet | Managed|https| direct | - |OK | No errors |
|Standard_D4s_v5| kubenet | Managed|http| lb | - | OK | No errors |
|Standard_D4s_v5| kubenet | Managed|http| direct | -| OK | No errors |
|Standard_D4s_v5 | azure | Managed|https| lb | -| NOK | `502 Bad Gateway` and `org.apache.http.ConnectionClosedException` errors |
|Standard_D4s_v5 | azure | Managed|https| lb | `net_netfilter_nf_conntrack_max` = 262144 | NOK | `502 Bad Gateway` and `org.apache.http.ConnectionClosedException` errors |
|Standard_D8s_v3| kubenet | Managed|https| lb | -| OK | No errors |
|Standard_D8s_v3| kubenet | Ephemeral|https| lb | - | OK | No errors |



## Observations

Observations so far:
- During the tests the load on the VM's is very low, typically well below 10% CPU on both sku types. Memory, while more difficult to assess, also seems to be abundant.
- Taking the Azure Load Balancer out of the flow results on zero errors during the test.
- Using the larger Sku size also results in zero errors even with the low load observed. `Managed` versus `Ephemeral` disk did not seem to make a difference. This might hint at some networking parameter being sized differently or hardware differences.
- In our tests `502 Bad Gateway` and `org.apache.http.ConnectionClosedException` errors only occur in the same scenario's which is surprising because the `org.apache.http.ConnectionClosedException` seems to be an issue between Jmeter and Application Gateway and the  `502 Bad Gateway` between Application Gateway and backend. It would be interesting to know if there is something in the Application Gateway error logs at the time the `org.apache.http.ConnectionClosedException` errors occur.
