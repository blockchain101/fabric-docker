#!/bin/bash

CHANNEL_NAME="$1"
ORGS_PROFILE="$2"
PRODUCTION_PATH="$3"
: ${CHANNEL_NAME:="mychannel"}
: ${ORGS_PROFILE:="TwoOrgs"}
: ${PRODUCTION_PATH:="/var/hyperledger/production"}
: ${TIMEOUT:="60"}
COUNTER=0
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ordererOrg1/orderers/ordererOrg1orderer1/cacerts/ordererOrg1-cert.pem

echo "Channel name : "$CHANNEL_NAME

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

setGlobals () {
        

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
                peerorg_name="peerOrg1"
                peer_seq=` expr $1 + 1`
		CORE_PEER_LOCALMSPID="Org1MSP"
	        CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$peerorg_name/peers/${peerorg_name}Peer${peer_seq}/cacerts/$peerorg_name-cert.pem"
        	CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$peerorg_name/peers/${peerorg_name}Peer${peer_seq}"
	else
                peerorg_name="peerOrg2"
                peer_seq=` expr $1 - 1`
		CORE_PEER_LOCALMSPID="Org2MSP"
	        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$peerorg_name/peers/${peerorg_name}Peer${peer_seq}/cacerts/$peerorg_name-cert.pem
        	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$peerorg_name/peers/${peerorg_name}Peer${peer_seq}
	fi
	CORE_PEER_ADDRESS=peer$1:7051
	env |grep CORE
}

createChannel() {
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ordererOrg1/orderers/ordererOrg1orderer1
	CORE_PEER_LOCALMSPID="OrdererMSP"

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer0:7050 -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/channel/channel-$ORGS_PROFILE-$CHANNEL_NAME.tx >&log.txt
	else
		peer channel create -o orderer0:7050 -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/channel/channel-$ORGS_PROFILE-$CHANNEL_NAME.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
        echo "cp $CHANNEL_NAME.block $PRODUCTION_PATH"
        cp $CHANNEL_NAME.block $PRODUCTION_PATH 
        echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry $1
	else
		COUNTER=0
	fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in $*; do
		setGlobals $ch
		joinWithRetry $ch
		echo "===================== PEER$ch joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		echo
	done
}

installChaincode () {
	PEER=$1
        CHAINCODE=$2
        CHAINCODE_ID=$3
        CHAINCODE_VER=$4
        setGlobals $PEER
	echo "peer chaincode install -n $CHAINCODE_ID -v $CHAINCODE_VER -p github.com/hyperledger/fabric/examples/chaincode/go/$CHAINCODE >&log.txt"
	peer chaincode install -n $CHAINCODE_ID -v $CHAINCODE_VER -p github.com/hyperledger/fabric/examples/chaincode/go/$CHAINCODE >&log.txt 
        res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
        CCINIT_ARGS=$2
        CHAINCODE_ID=$3
        CHAINCODE_VER=$4
	setGlobals $PEER
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		echo "peer chaincode instantiate -o orderer0:7050 -C $CHANNEL_NAME -n $CHAINCODE_ID -v $CHAINCODE_VER -c $CCINIT_ARGS -P \"OR('Org1MSP.member','Org2MSP.member')\" >&log.txt "
		peer chaincode instantiate -o orderer0:7050 -C $CHANNEL_NAME -n $CHAINCODE_ID -v $CHAINCODE_VER -c $CCINIT_ARGS -P "OR('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		echo "peer chaincode instantiate -o orderer0:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_ID -v $CHAINCODE_VER -c $CCINIT_ARGS -P \"OR('Org1MSP.member','Org2MSP.member')\" >&log.txt"
		peer chaincode instantiate -o orderer0:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_ID -v $CHAINCODE_VER -c $CCINIT_ARGS -P "OR('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeQuery () {
  PEER=$1
  CCQUERY_ARGS=$2 
  CHAINCODE_ID=$3
  EXPECTED_RSLT=$4
  echo "===================== Querying on PEER$PEER on channel '$CHANNEL_NAME'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     echo "peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_ID -c $CCQUERY_ARGS >&log.txt "
     peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_ID -c $CCQUERY_ARGS >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$EXPECTED_RSLT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
  fi
}

chaincodeInvoke () {
        PEER=$1
        CCINVOKE_ARGS=$2
        CHAINCODE_ID=$3
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		echo "peer chaincode invoke -o orderer0:7050 -C $CHANNEL_NAME -n $CHAINCODE_ID -c $CCINVOKE_ARGS >&log.txt"
		peer chaincode invoke -o orderer0:7050 -C $CHANNEL_NAME -n $CHAINCODE_ID -c "$CCINVOKE_ARGS" >&log.txt
	else
		echo "peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_ID -c $CCINVOKE_ARGS >&log.txt"
		peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_ID -c $CCINVOKE_ARGS >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

## Create channel
createChannel

## Join all the peers to the channel
joinChannel 0 2 3


## Install chaincode on Peer0/Org0 and Peer2/Org1
installChaincode 0 chaincode_example02 mycc 1.0
installChaincode 2 chaincode_example02 mycc 1.0

#Instantiate chaincode on Peer2/Org1
echo "Instantiating chaincode ..."
instantiateChaincode 2 '{"Args":["init","a","100","b","200"]}' mycc 1.0

#Query on chaincode on Peer0/Org0
chaincodeQuery 0 '{"Args":["query","a"]}' mycc 100

#Invoke on chaincode on Peer0/Org0
echo "send Invoke transaction ..."
chaincodeInvoke 0 '{"Args":["invoke","a","b","10"]}' mycc

## Install chaincode on Peer3/Org1
installChaincode 3 chaincode_example02 mycc 1.0

#Query on chaincode on Peer3/Org1, check if the result is 90
chaincodeQuery 3 '{"Args":["query","a"]}' mycc 90

echo
echo "===================== All GOOD, End-2-End chaincode_example02 test completed ===================== "
echo
echo "waiting 10s to start marbles02 deploying and invoke..."
sleep 10
echo "===================== Start deploying marbles02 ===================== "
echo "Installing chaincode ..."
installChaincode 0 marbles02 marbles02 1.0
installChaincode 2 marbles02 marbles02 1.0

echo "Instantiating chaincode ..."
instantiateChaincode 2 '{"Args":["init","100"]}' marbles02 1.0

echo "Querying chaincode ..."
chaincodeQuery 0 '{"Args":["read","selftest"]}' marbles02 100

echo "Invoking chaincode init_owner o0..."
chaincodeInvoke 0 '{"Args":["init_owner","o0","dummy0","United Marbles"]}' marbles02

echo "Invoking chaincode init_owner o1 ..."
chaincodeInvoke 2 '{"Args":["init_owner","o1","dummy1","eMarbles"]}' marbles02

echo "sleeping 10s"
sleep 10

echo "Invoking chaincode init_marble m01~05..."
chaincodeInvoke 0 '{"Args":["init_marble","m01","red","1","o0","United Marbles"]}' marbles02
chaincodeInvoke 0 '{"Args":["init_marble","m02","red","1","o0","United Marbles"]}' marbles02
chaincodeInvoke 0 '{"Args":["init_marble","m03","red","1","o0","United Marbles"]}' marbles02
chaincodeInvoke 0 '{"Args":["init_marble","m04","red","1","o0","United Marbles"]}' marbles02
chaincodeInvoke 0 '{"Args":["init_marble","m05","red","1","o0","United Marbles"]}' marbles02

echo "sleeping 10s"
sleep 10

echo "Invoking chaincode init_marble m11~m15..."
chaincodeInvoke 2 '{"Args":["init_marble","m11","blue","30","o1","eMarbles"]}' marbles02
chaincodeInvoke 2 '{"Args":["init_marble","m12","blue","30","o1","eMarbles"]}' marbles02
chaincodeInvoke 2 '{"Args":["init_marble","m13","blue","30","o1","eMarbles"]}' marbles02
chaincodeInvoke 2 '{"Args":["init_marble","m14","blue","30","o1","eMarbles"]}' marbles02
chaincodeInvoke 2 '{"Args":["init_marble","m15","blue","30","o1","eMarbles"]}' marbles02

echo "sleeping 10s"
sleep 10
echo "Invoking chaincode set_owner m01->o1..."
chaincodeInvoke 2 '{"Args":["set_owner","m01","o1","United Marbles"]}' marbles02

echo "sleeping 10s"
sleep 10
echo "Invoking chaincode init_marble m11->o0..."
chaincodeInvoke 2 '{"Args":["set_owner","m11","o0","eMarbles"]}' marbles02

echo "============================= Deployed marbles02 and invoked OK ============================= "
exit 0
