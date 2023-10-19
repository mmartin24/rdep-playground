#!/bin/bash

set -e

# Shutting down Rancher Desktop
echo -e '\n ---------- SHUTTING DOWN RDCTL ------------ \n'
rdctl shutdown 

# Remove Rancher
echo -e '\n ---------- DELETING RANCHER DESKTOP ------------ \n'
rm -rf $HOME/Applications/Rancher\ Desktop.app
# wait 5

# Remove .rd directory
echo -e '\n ---------- DELETING '.rd' directory ------------ \n'
rm -rf $HOME/.rd