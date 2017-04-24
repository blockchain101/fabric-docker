# dockerfiles
docker file create blockchain101/fabric-ca:1.0 based on hyperledger/fabric-ca:x86_64-1.0.0-alpha which is built using source code
docker file create blockchain101/fabric-peer:1.0 based on hyperledger/fabric-peer:x86_64-1.0.0-alpha which is built using source code
docker file create blockchain101/fabric-orderer:1.0 based on hyperledger/fabric-orderer:x86_64-1.0.0-alpha which is built using source code
docker file create blockchain101/fabric-couchdb:1.0 based on hyperledger/fabric-couchdb:x86_64-1.0.0-alpha which is built using source code
docker file create hyperledger/fabric-ccenv:latest based on hyperledger/fabric-ccenv:x86_64-1.0.0-alpha which is built using source code
docker file create blockchain101/fabric-cli:1.0 based on  blockchain101/fabric-peer:1.0 which is built using source code
docker files create blockchain101/fabric-hfc:1.0 based on blockchain101/ubuntu16.04-dev:node6.9-python2.7-makegcc-git which is built from scrach using ubuntu:16.04 image in docker hub

# fabric-dev-docker
docker compose file to run docker containers using above blockchain101/fabric-orderer:1.0, blockchain101/fabric-peer:1.0, blockchain101/fabric-cli:1.0 images
3 fabric nodes containers: fabric-dev-orderer, fabric-dev-peer, fabric-dev-cli
an auto-config script will be invoked to create channel wich channel name "chdev" and one default org msp id with "DEFAULT", join channel, install example02/marble02 chaincode and invoke/query chaincode

# fabric-testnet-docker
docker compose file to run docker containers using above blockchain101/fabric-ca:1.0, blockchain101/fabric-orderer:1.0, blockchain101/fabric-peer:1.0, hyperledger/fabric-ccenv:x86_64-1.0.0-alpha, blockchain101/fabric-hfc:1.0,blockchain101/fabric-cli:1.0  images
10 fabric nodes containers: ca0, ca1, orderer0, peer0~peer3, hfc0, hfc1, cli 
an auto-config script will be invoked to create channel wich channel name "ch1" and one TwoOrgs with msp id "OrdererMSP", "Org1Msp", "Org2Msp", 
orderer0 using msp "OrdererMSP"; peer0~1 belong to org1 using msp "Org1Msp", peer2~3 belong to org2 join channel,
using cli install example02/marble02 chaincode and invoke/query chaincode
using hfc0 which authenticatig with ca0 to access peer0 with marbles app installed and running with 3001 port.
using hfc1 which authenticatig with ca1 to access peer2 with marbles app installed and running with 3002 port.
you could also using local marbles app to access docker contained apps.

TODO: enable tls

