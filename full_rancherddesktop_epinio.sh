#!/bin/bash

set -e

## Installing Rancher Desktop
source rd_install_mac.sh
echo -e '\n ---------- Sleeping 60 seconds before installing Epinio ------------ \n'
sleep 50

## Installing Epinio
source ep_install_on_rd.sh

## Uninstalling Epinio
source ep_uninstall_on_rd.sh

## Removal of Rancher Desktop
source rd_uninstall.sh
