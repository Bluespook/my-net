#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=manufacturer
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/manufacturer.com/tlsca/tlsca.manufacturer.com-cert.pem
CAPEM=organizations/peerOrganizations/manufacturer.com/ca/ca.manufacturer.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/manufacturer.com/connection-manufacturer.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/manufacturer.com/connection-manufacturer.yaml

ORG=supplier
P0PORT=9051
CAPORT=9054
PEERPEM=organizations/peerOrganizations/supplier.com/tlsca/tlsca.supplier.com-cert.pem
CAPEM=organizations/peerOrganizations/supplier.com/ca/ca.supplier.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/supplier.com/connection-supplier.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/supplier.com/connection-supplier.yaml

ORG=distributor
P0PORT=6051
CAPORT=6054
PEERPEM=organizations/peerOrganizations/distributor.com/tlsca/tlsca.distributor.com-cert.pem
CAPEM=organizations/peerOrganizations/distributor.com/ca/ca.distributor.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/distributor.com/connection-distributor.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/distributor.com/connection-distributor.yaml

ORG=customer
P0PORT=8051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/customer.com/tlsca/tlsca.customer.com-cert.pem
CAPEM=organizations/peerOrganizations/customer.com/ca/ca.customer.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/customer.com/connection-customer.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/customer.com/connection-customer.yaml