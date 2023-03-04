CHANNEL_NAME=${1:-"mychannel"}
chaincode_name=$2
chaincode_path=$3
chaincode_version=${4:-"1.0"}
chaincode_sequence=${5:-"1"}
chaincode_init=${6:-"InitLedger"}


. scripts/env.sh
FABRIC_CFG_PATH=${PWD}/configtx

function multi_parameters() {
    peers=""
    peer_address=""
    num="1"
    while [ $# -ne 0 ] 
        do
            set_identity $1
            single="peer0.$1.com"
            peers="$peers $single"
            peer_address="$peer_address --peerAddresses $CORE_PEER_ADDRESS"

            # echo $1

            trans=$(echo "$1" | tr [:lower:] [:upper:])

            # echo $trans
            # echo PEER0_${trans}_CA
            tls_info=$(eval echo "--tlsRootCertFiles \$PEER0_${trans}_CA")

            peer_address="$peer_address $tls_info"
            shift
        done
    peers="$(echo -e "$peers" | sed -e 's/^[[:space:]]*//')"

    # echo $peer_address
    # echo $peers
}

function package() {
    echo "package chaincode"
    set -x
    peer lifecycle chaincode package $chaincode_name.tar.gz --path $chaincode_path --label ${chaincode_name}_${chaincode_version} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
}

function install() {
    ORG=$1
    set_identity $ORG
    echo "install chaincode with org $ORG"
    set -x
    peer lifecycle chaincode install $chaincode_name.tar.gz >&log.txt
    res=$?
    { set +x; } 2>/dev/null
}

function query_installed() {
    ORG=$1
    set_identity $ORG
    echo "query installed chaincode with org $ORG"
    set -x
    peer lifecycle chaincode queryinstalled >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    PACKAGE_ID=$(sed -n "/${chaincode_name}_${chaincode_version}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
}

function approve() {
    ORG=$1
    set_identity $ORG
    echo "approve chaincode for org $ORG"
    set -x
    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.orderer.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${chaincode_name} --version ${chaincode_version} --package-id ${PACKAGE_ID} --sequence ${chaincode_sequence} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
}

function check_commit_status() {
    ORG=$1
    set_identity $ORG
    echo "checking----------- with org $ORG"
    set -x
    peer lifecycle chaincode checkcommitreadiness -C $CHANNEL_NAME -n $chaincode_name -v $chaincode_version --sequence $chaincode_sequence --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
}

function commit() {
    multi_parameters $@
    echo "commiting----------- with org $*"
    set -x
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.orderer.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${chaincode_name} --version ${chaincode_version} --sequence ${chaincode_sequence} $peer_address >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
}

function query_commit() {
    ORG=$1
    set_identity $ORG
    echo "query commit status with org $ORG"
    set -x
    peer lifecycle chaincode querycommitted -C $CHANNEL_NAME -n $chaincode_name >&log.txt
    res=$?
    { set +x; } 2>/dev/null
}

function invoke_init() {
    multi_parameters $@
    fcn_call='{"function":"'${chaincode_init}'","Args":[]}'
    set -x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.orderer.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${chaincode_name} $peer_address -c ${fcn_call} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
}


package

install manufacturer
install supplier
install distributor

query_installed manufacturer

approve manufacturer
approve supplier
approve distributor

check_commit_status manufacturer

commit manufacturer supplier distributor

query_commit manufacturer
query_commit distributor

if [ $chaincode_init = "NA" ] ; then
    echo -e "${C_BLUE}No need to initialize${C_RESET}"
else
    invoke_init manufacturer supplier distributor
fi
