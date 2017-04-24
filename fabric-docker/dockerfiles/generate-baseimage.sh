gzip -d github.com.tar.gz
docker build -f Dockerfile_baseimage0.3.0 -t hyperledger/fabric-baseimage:latest .
