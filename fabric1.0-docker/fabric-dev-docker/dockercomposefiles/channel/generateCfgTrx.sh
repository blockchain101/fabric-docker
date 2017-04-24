#!/bin/bash

CHANNEL_NAME=$1
FABRIC_HOME=~/fabric1.0/src/github.com/hyperledger/fabric 
ORGS_PROFILE=$2
if [ -z "$1" ]; then
	echo "Setting channel to default name 'mychannel'"
	CHANNEL_NAME="mychannel"
fi
if [ -z "$2" ]; then
	echo "Setting orgs profile to default name 'TwoOrgs'"
        ORGS_PROFILE=TwoOrgs
fi
echo "Channel name - "$CHANNEL_NAME  "Organization profile - "$ORGS_PROFILE
echo

#Backup the original configtx.yaml
cp $FABRIC_HOME/common/configtx/tool/configtx.yaml $FABRIC_HOME/common/configtx/tool/configtx.yaml.orig
cp configtx.profile $FABRIC_HOME/common/configtx/tool/configtx.yaml

echo "Generating genesis block"
$FABRIC_HOME/build/bin/configtxgen -profile $ORGS_PROFILE -outputBlock orderer-$ORGS_PROFILE.block

echo "Generating channel configuration transaction"
$FABRIC_HOME/build/bin/configtxgen -profile $ORGS_PROFILE -outputCreateChannelTx channel-$ORGS_PROFILE-$CHANNEL_NAME.tx -channelID $CHANNEL_NAME

#reset configtx.yaml file to its original
cp $FABRIC_HOME/common/configtx/tool/configtx.yaml.orig $FABRIC_HOME/common/configtx/tool/configtx.yaml
rm $FABRIC_HOME/common/configtx/tool/configtx.yaml.orig
