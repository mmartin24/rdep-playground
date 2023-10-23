#!/bin/bash

set -e

## Install Epinio CLI
echo -e '\n ---------- INSTALLING EPINIO CLI ------------ \n'
curl -o epinio -L https://github.com/epinio/epinio/releases/download/v1.10.0/epinio-darwin-x86_64
chmod +x epinio
# sudo mv epinio /usr/local/bin/epinio
mv epinio /usr/local/bin/epinio

# Set context to Rancher Desktop
echo -e '\n ---------- SETTING CONTEXT to Rancher Desktop ------------ \n'
kubectl config get-contexts
kubectl config use-context rancher-desktop
sleep 5

## Install Epino
echo -e '\n ---------- INSTALL CERT MANAGER ------------ \n'
kubectl create namespace cert-manager 
helm repo add jetstack https://charts.jetstack.io 
helm repo update 
helm upgrade --install --wait cert-manager  --namespace cert-manager jetstack/cert-manager  --set installCRDs=true  --set "extraArgs[0]=--enable-certificate-owner-ref=true"

## Output df-h and k get events
echo -e '\n ---------- Output df-h and k get events ------------ \n'
df -h
kubectl get events -A


echo -e '\n ---------- INSTALLING EPINIO ------------ \n'
helm repo add epinio https://epinio.github.io/helm-charts 
#MYEPINIODOMAIN=`kubectl get svc -n kube-system traefik | awk '{print $4}' | tail --lines=+2` 
MYEPINIODOMAIN='127.0.0.1'
helm upgrade --install epinio -n epinio --create-namespace epinio/epinio \
    --set global.domain=${MYEPINIODOMAIN}.nip.io \
    --set server.disableTracking="true" 

kubectl wait --for=condition=Ready --timeout=180s pods --all -n epinio

## Check it can login
echo -e '\n ---------- CHECKING EPINIO LOGIN ------------ \n'
yes | epinio login -u admin -p password "https://epinio.${MYEPINIODOMAIN}.nip.io"
epinio info

epinio settings update-ca

## Push sample app
echo -e '\n ---------- Pushing app ------------ \n'
APPNAME=go-app
epinio push --name $APPNAME --git https://github.com/epinio/example-go,main --env='BP_KEEP_FILES=static/*'

# ## Push Jenkins app
# echo -e '\n ---------- Pushing app ------------ \n'
# APPNAME=jenkins-app
# epinio app push --name $APPNAME --container-image-url jenkins/jenkins

echo -e '\n ---------- Waiting for condition available in workspace before curl on app ------------ \n'
# kubectl wait --for=condition=Available --timeout=120s deployment --all --namespace workspace
Sleep 40

## Check app returns a 200 otherwise exit
CURLAPP=$(curl -fkLI "https://${APPNAME}.${MYEPINIODOMAIN}.nip.io")
APPRESPONSE=$(echo $CURLAPP 2>/dev/null | head -n 1 | cut -d$' ' -f2)

echo $CURLAPP

if [[ $APPRESPONSE -eq 200 ]]; then
    echo "App pushed ok, request response is '${APPRESPONSE}'"   
else
    echo "App pushed, but its request response was not 200". Exiting
    exit 1
fi
