#!/bin/bash

set -e

echo -e '\n ---------- DOWLOADING RANCHER DESKTOP ------------ \n'
VERSION=1.10.0
FILE=Rancher.Desktop-$VERSION-mac.x86_64.zip
curl -sLO --output-dir /tmp https://github.com/rancher-sandbox/rancher-desktop/releases/download/v$VERSION/$FILE

echo -e '\n ---------- REMOVING PREVIOUS VERSIONS OF RANCHER DESKTOP ------------ \n'
APP="Rancher Desktop.app"
rm -rf "$HOME/Applications/$APP"
rm -rf $HOME/.rd

echo -e '\n ---------- UNZIPPING NEW RANCHER DESKTOP ------------ \n'
unzip -o "/tmp/$FILE" "$APP/*" -d $HOME/Applications >/dev/null

echo -e '\n ---------- INSTALLING RANCHER DESKTOP ------------ \n'
open $HOME/Applications/Rancher\ Desktop.app/Contents/MacOS/Rancher\ Desktop 
sleep 60

echo -e '\n ---------- STARTING RANCHER DESKTOP WITH RDCTL ------------ \n'
RD_CONTAINER_ENGINE=moby

args=(
        --application.updater.enabled=false
        --container-engine.name="$RD_CONTAINER_ENGINE"
        --kubernetes.enabled=true
        --application.admin-access=false
        --application.path-management-strategy rcfiles
        --virtual-machine.memory-in-gb 2
    )
rdctl start "${args[@]}" "$@" &
rdctl set --application.path-management-strategy manual
rdctl set --application.path-management-strategy rcfiles


# Path to rdctl: /Users/mamartin/.rd/bin
