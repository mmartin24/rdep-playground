#!/bin/bash

set -e

## Uninstall Epinio
echo -e '\n ---------- UNINSTALLING EPINIO ------------ \n'
helm uninstall -n epinio epinio --wait

## Uninstall cert manager
echo -e '\n ---------- UNINSTALLING CERT MANAGER ------------ \n'
helm uninstall cert-manager -n cert-manager --wait
