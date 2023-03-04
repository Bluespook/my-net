#!/bin/bash

#添加环境变量
export PATH=${PWD}/bin:${PATH}
export FABRIC_CFG_PATH=${PWD}/configtx

#在CA模式下使用pem创建组织，太复杂先不写了
function create_gree() {
    echo "enrolling the CA admin"
    mkdir -p organizations/peerOrganizations/manufacturer.com/

    export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/manufacturer.com/
}


#创建组织
function create_org() {
    #加密配置文件
    set -x
    cryptogen generate --config=./organizations/encrypt/org1.yaml --output="organizations"
    cryptogen generate --config=./organizations/encrypt/org2.yaml --output="organizations"
    cryptogen generate --config=./organizations/encrypt/org3.yaml --output="organizations"
    cryptogen generate --config=./organizations/encrypt/org4.yaml --output="organizations"
    cryptogen generate --config=./organizations/encrypt/orderer.yaml --output="organizations"
    { set +x; } 2>/dev/null
    #生成CCP文件
    ./organizations/ccp-generate.sh
}

function create_consortium() {
    #创建系统通道
    set -x
    configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
    { set +x; } 2>/dev/null
}

C_RED='\033[0;31m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_RESET='\033[0m'

COMPOSE_FILES="-f docker/docker-compose-test-net.yaml"

if [ $# -lt 1 ] ; then
        echo -e "Please choose the pattern: ${C_BLUE}up, down, channel${C_RESET}"
else
    MODE=$1
    shift
fi

if [ $# -ge 1 ] ; then
    if [ $MODE = "--channel" ] ; then 
        CHANNEL_NAME=$1
    elif [ $MODE = "deploy" ] ; then
        :
    else
        echo -e "Please choose the pattern: ${C_BLUE}up, down, channel${C_RESET}"
    fi
fi

while [ $# -ge 1 ] ; do
    key=$1
    case $key in
    "-ccn" )
        chaincode_name=$2
        shift
        ;;
    "-c" )
        CHANNEL_NAME=$2
        shift
        ;;
    "-ccp" )
        chaincode_path=$2
        shift
        ;;
    "-ccv" )
        chaincode_version=$2
        shift
        ;;
    "-ccs" )
        chaincode_sequence=$2
        shift
        ;;
    * )
        :
        ;;
    esac
    shift
done

function networkUp() {
    create_org
    create_consortium

    docker-compose ${COMPOSE_FILES} up -d 2>&1
}

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

function networkDown() {
    docker-compose $COMPOSE_FILES down --volumes --remove-orphans
    removeUnwantedImages
    rm -rf channel-artifacts
    rm -rf organizations/ordererOrganizations
    rm -rf organizations/peerOrganizations
    rm *.tar.gz
}

function create_channel() {
    # . scripts/env.sh
    CHANNEL_NAME=$1
    : ${CHANNEL_NAME:="mychannel"}
    BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

    if [ ! -d "channel-artifacts" ]; then
	    mkdir channel-artifacts
    fi
    
    # 通道创建交易
    set -x
    configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ${PWD}/channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
    { set +x; } 2>/dev/null

    # 创建通道
    # FABRIC_CFG_PATH=${PWD}/config
    set_identity manufacturer
    set -x
    peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.orderer.com \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&create-log.txt
    res=$?
    { set +x; } 2>/dev/null

    cat create-log.txt

    join_channel manufacturer
    join_channel supplier
    join_channel distributor

    docker exec cli ./scripts/anchor-peer.sh manufacturer $CHANNEL_NAME
    docker exec cli ./scripts/anchor-peer.sh supplier $CHANNEL_NAME
    docker exec cli ./scripts/anchor-peer.sh distributor $CHANNEL_NAME
}

function create_channel2() {
    # . scripts/env.sh
    CHANNEL_NAME="channel2"
    BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

    if [ ! -d "channel-artifacts" ]; then
	    mkdir channel-artifacts
    fi
    
    # 通道创建交易
    set -x
    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ${PWD}/channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
    { set +x; } 2>/dev/null

    # 创建通道
    # FABRIC_CFG_PATH=${PWD}/config
    set_identity manufacturer
    set -x
    peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.orderer.com \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&create-log.txt
    res=$?
    { set +x; } 2>/dev/null

    cat create-log.txt

    join_channel manufacturer
    join_channel customer

    docker exec cli ./scripts/anchor-peer.sh manufacturer $CHANNEL_NAME
    docker exec cli ./scripts/anchor-peer.sh customer $CHANNEL_NAME
}

function join_channel() {
    ORG=$1
    set_identity $ORG
    set -x
    peer channel join -b $BLOCKFILE >&join-log.txt
    res=$?
    { set +x; } 2>/dev/null

    cat join-log.txt
}

function deploy_cc() {
    . deploy.sh $CHANNEL_NAME $chaincode_name $chaincode_path $chaincode_version $chaincode_sequence
}

. scripts/env.sh

if [ $MODE = "up" ] ; then
    networkUp
elif [ $MODE = "--channel" ] ; then
    create_channel $CHANNEL_NAME
    # create_channel2
elif [ $MODE = "down" ] ; then
    networkDown
elif [ $MODE = "deploy" ] ; then
    deploy_cc
else
    echo -e "Please choose the pattern: ${C_BLUE}up, down, channel${C_RESET}"
fi