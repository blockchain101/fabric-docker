# dockerfiles
docker files create blockchain101/fabric-hfc:0.6.1, blockchain101/fabric-peer:0.6.1 based on hyperledger/fabric-peer:x86_64-0.6.1-preview in docker hub
docker file create blockchain101/fabric-membersrvc:0.6.1 based on hyperledger/fabric-membersrvc:x86_64-0.6.1-preview in docker hub
docker file create hyperledger/fabric-baseimage:latest based on hyperledger/fabric-baseimage:x86_64-0.2.1


# fabric-dev-docker
docker compose file to run docker containers using above blockchain101/fabric-hfc:0.6.1, blockchain101/fabric-peer:0.6.1, blockchain101/fabric-membersrvc:0.6.1 images
3 fabric nodes containers: fabric-dev-membersrvc, fabric-dev-peer, fabric-dev-client

# fabric-testnet-docker
docker compose file to run docker containers using above blockchain101/fabric-hfc:0.6.1, blockchain101/fabric-peer:0.6.1, blockchain101/fabric-membersrvc:0.6.1, hyperledger/fabric-baseimage:latest images
7 fabric nodes containers: mymembersrvc, vp0~vp3, myhfc connecting to vp0, myhfc3 connecting to vp3


