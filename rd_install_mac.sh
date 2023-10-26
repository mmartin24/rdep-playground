#!/bin/bash

set -e

echo -e '\n ---------- REMOVING PREVIOUS VERSIONS OF RANCHER DESKTOP ------------ \n'
APP="Rancher Desktop.app"
rm -rf $HOME/Applications/$APP
rm -rf $HOME/.rd

echo -e '\n ---------- DOWLOADING RANCHER DESKTOP ------------ \n'
VERSION=1.10.0
FILE=Rancher.Desktop-$VERSION-mac.x86_64.zip
curl -sLO --output-dir /tmp https://github.com/rancher-sandbox/rancher-desktop/releases/download/v$VERSION/$FILE

echo -e '\n ---------- UNZIPPING NEW RANCHER DESKTOP ------------ \n'
unzip -o "/tmp/$FILE" "$APP/*" -d $HOME/Applications >/dev/null

# echo -e '\n ---------- INSTALLING RANCHER DESKTOP ------------ \n'
# open $HOME/Applications/Rancher\ Desktop.app/Contents/MacOS/Rancher\ Desktop 
# echo -e "\n ---------- Return code is $? ------------ \n"
# echo -e '\n ---------- Sleeping 40 seconds before using rdctl commands ------------ \n'
# sleep 40

echo -e '\n ---------- STARTING RANCHER DESKTOP WITH RDCTL ------------ \n'
echo -e '\n ---------- EXPORT rdctl within RD just created ------------ \n'

export PATH=$PATH:$HOME/Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/

RD_CONTAINER_ENGINE=moby

args=(
        --application.updater.enabled=false
        --container-engine.name="$RD_CONTAINER_ENGINE"
        --kubernetes.enabled=true
        --application.admin-access=false
        --application.path-management-strategy rcfiles
        --virtual-machine.memory-in-gb 6   
    )
echo -e '\n ---------- Applying "rdctl start..." ------------ \n'
rdctl start "${args[@]}" "$@" &
echo -e '\n ---------- Sleeping 40 seconds------------ \n'
sleep 40

# Script to wait for right conditions to be ready prior proceeding with rdctl commands
echo -e '\n ---------- Checking k8s resources are ready ------------ \n'
max_attempts=200
attempt=0
K8S_API_EP=https://127.0.0.1:6443

while [ "$attempt" -lt "$max_attempts" ]; do
  if curl -Isk $K8S_API_EP | head -n 1 | grep -q "401"; then
    echo "K8s API is available"
    break
  else
    echo "K8s API NOT available (Attempt: $attempt/$max_attempts)"
    attempt=$((attempt+1))
  fi
  sleep 2
done

if [ "$attempt" -ge "$max_attempts" ]; then
  echo "Kubernetes API unreachable after $max_attempts attempts. Exiting."; exit 5
fi

echo -e '\n ---------- Sleeping 25 seconds before kubectl check on ready conditions ------------ \n'
sleep 25

kubectl wait --for=condition=Available --timeout=120s deployments --all -n kube-system


##
# retry() {
#     local cmd=$1
#     local tries=${2:-10}
#     local delay=${3:-30}
#     local i
#     for ((i=1; i<=tries; i++)); do
#         timeout 25 bash -c "$cmd" && break || echo "RETRY #$i: $cmd"
#         [ $i -ne $tries ] && sleep $delay || { echo "FAILURE after $i tries: $cmd"; exit 5; }
#     done
# }

# K8S_API_EP=https://127.0.0.1:6443
# retry "curl -Isk $K8S_API_EP | head -n 1 | grep -q '401'" 200 2
# retry 'kubectl wait --for=condition=Ready --timeout=120s nodes --all' 10 5
# retry 'kubectl wait --for=condition=Available --timeout=120s deployments --all -n kube-system' 10 5
##

echo -e '\n ---------- Sleeping 40 seconds before further set on rdctl commands ------------ \n'
# sleep 40
echo -e '\n ---------- Applying "--application.path-management-strategy manual..." ------------ \n'
rdctl set --application.path-management-strategy manual
echo -e '\n ---------- Applying "--application.path-management-strategy rcfiles..." ------------ \n'
rdctl set --application.path-management-strategy rcfiles
