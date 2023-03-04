#!/bin/bash

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/orderer.com/orderers/orderer.orderer.com/msp/tlscacerts/tlsca.orderer.com-cert.pem
export PEER0_MANUFACTURER_CA=${PWD}/organizations/peerOrganizations/manufacturer.com/peers/peer0.manufacturer.com/tls/ca.crt
export PEER0_SUPPLIER_CA=${PWD}/organizations/peerOrganizations/supplier.com/peers/peer0.supplier.com/tls/ca.crt
export PEER0_DISTRIBUTOR_CA=${PWD}/organizations/peerOrganizations/distributor.com/peers/peer0.distributor.com/tls/ca.crt

export PEER0_CUSTOMER_CA=${PWD}/organizations/peerOrganizations/customer.com/peers/peer0.customer.com/tls/ca.crt


function set_identity() {
    USE_ORG=$1
    if [ $USE_ORG = "manufacturer" ] ; then
        export CORE_PEER_LOCALMSPID="ManufacturerMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MANUFACTURER_CA
        export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturer.com/users/Admin@manufacturer.com/msp
        export CORE_PEER_ADDRESS=localhost:7051
    elif [ $USE_ORG = "supplier" ] ; then
        export CORE_PEER_LOCALMSPID="SupplierMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SUPPLIER_CA
        export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/supplier.com/users/Admin@supplier.com/msp
        export CORE_PEER_ADDRESS=localhost:9051
    elif [ $USE_ORG = "distributor" ] ; then
        export CORE_PEER_LOCALMSPID="DistributorMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_DISTRIBUTOR_CA
        export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/distributor.com/users/Admin@distributor.com/msp
        export CORE_PEER_ADDRESS=localhost:6051
    elif [ $USE_ORG = "customer" ] ; then
        export CORE_PEER_LOCALMSPID="CustomerMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CUSTOMER_CA
        export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customer.com/users/Admin@customer.com/msp
        export CORE_PEER_ADDRESS=localhost:8051
    else
        echo "unkown org"
    fi
}

function set_identity_cli() {
    USE_ORG=$1
    set_identity $USE_ORG
    if [ $USE_ORG = "manufacturer" ] ; then
        export CORE_PEER_ADDRESS=peer0.manufacturer.com:7051
    elif [ $USE_ORG = "supplier" ] ; then
        export CORE_PEER_ADDRESS=peer0.supplier.com:9051
    elif [ $USE_ORG = "distributor" ] ; then
        export CORE_PEER_ADDRESS=peer0.distributor.com:6051
    elif [ $USE_ORG = "customer" ] ; then
        export CORE_PEER_ADDRESS=peer0.customer.com:8051
    else
        echo "unkown org"
    fi
}