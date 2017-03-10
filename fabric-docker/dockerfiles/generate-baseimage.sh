mv github.com.tar.java github.com.tar.gz
gzip -d github.com.tar.gz
docker build -f Dockerfile_baseimage -t hyperledger/fabric-baseimage:latest .