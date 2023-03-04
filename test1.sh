#!/bin/bash
trans=$(echo "$1" | tr [:lower:] [:upper:])
echo "--tlsRootCertFiles \$PEER0_${trans}_CA"
