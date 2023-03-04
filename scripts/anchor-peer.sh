#!/bin/bash
. scripts/env.sh

function setAnchorPeer() {
    local ORG=$1
    local CHANNEL_NAME=$2
    set_identity_cli $ORG

    # 获取通道配置，以protobuf格式的形式
    set -x
    peer channel fetch config config_block.pb -o orderer.orderer.com:7050 --ordererTLSHostnameOverride orderer.orderer.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
    { set +x; } 2>/dev/null

    # 将通道配置解析为json格式，通道配置是区块，所以格式为.Block
    set -x
    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >"${CORE_PEER_LOCALMSPID}config.json"
    { set +x; } 2>/dev/null

    if [ $ORG = "manufacturer" ] ; then
        HOST="peer0.manufacturer.com"
        PORT=7051
    elif [ $ORG = "supplier" ] ; then
        HOST="peer0.supplier.com"
        PORT=9051
    elif [ $ORG = "distributor" ] ; then
        HOST="peer0.distributor.com"
        PORT=6051
    elif [ $ORG = "customer" ] ; then
        HOST="peer0.customer.com"
        PORT=8051
    else
        echo "unkown org"
        exit 1
    fi

    # 修改配置
    set -x
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
    { set +x; } 2>/dev/null

    # 获取配置更新的protobuf文件
    config_update ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx

    set -x
    peer channel update -o orderer.orderer.com:7050 --ordererTLSHostnameOverride orderer.orderer.com -c ${CHANNEL_NAME} -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
    { set +x; } 2>/dev/null

    cat log.txt
}

function config_update() {
    CHANNEL=$1
    OLD_CONFIG=$2
    NEW_CONFIG=$3
    OUTPUT=$4

    set -x
    configtxlator proto_encode --input ${OLD_CONFIG} --type common.Config >old_config.pb
    configtxlator proto_encode --input ${NEW_CONFIG} --type common.Config >new_config.pb
    configtxlator compute_update --channel_id ${CHANNEL} --original old_config.pb --updated new_config.pb >config_update.pb
    configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
    configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >${OUTPUT}
    { set +x; } 2>/dev/null
}

setAnchorPeer $1 $2