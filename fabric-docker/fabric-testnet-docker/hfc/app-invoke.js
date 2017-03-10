/*
 Copyright IBM Corp 2016 All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

/*
 * A simple application utilizing the Node.js Client SDK to:
 * 1) Enroll a user
 * 2) User deploys chaincode
 * 3) User queries chaincode
 */
// "HFC" stands for "Hyperledger Fabric Client"
var hfc = require("hfc");

console.log(" **** starting HFC sample ****");


// get the addresses from the docker-compose environment
var PEER_ADDRESS         = process.env.PEER_ADDRESS;
var MEMBERSRVC_ADDRESS   = process.env.MEMBERSRVC_ADDRESS;
var USER_NAME = process.env.USER_NAME;
var USER_PASSWORD = process.env.USER_PASSWORD;

var chain, chaincodeID;

// Create a chain object used to interact with the chain.
// You can name it anything you want as it is only used by client.
chain = hfc.newChain("mychain");
// Initialize the place to store sensitive private key information
chain.setKeyValStore( hfc.newFileKeyValStore('/tmp/keyValStore') );
// Set the URL to membership services and to the peer
console.log("member services address ="+MEMBERSRVC_ADDRESS);
console.log("peer address ="+PEER_ADDRESS);
chain.setMemberServicesUrl("grpc://"+MEMBERSRVC_ADDRESS);
chain.addPeer("grpc://"+PEER_ADDRESS);

// The following is required when the peer is started in dev mode
// (i.e. with the '--peer-chaincodedev' option)
var mode =  process.env['DEPLOY_MODE'];
console.log("DEPLOY_MODE=" + mode);
if (mode === 'dev') {
    chain.setDevMode(true);
    //Deploy will not take long as the chain should already be running
    chain.setDeployWaitTime(10);
} else {
    chain.setDevMode(false);
    //Deploy will take much longer in network mode
    chain.setDeployWaitTime(120);
}


chain.setInvokeWaitTime(10);

// Begin by enrolling the user
enroll();

// Enroll a user.
function enroll() {
   console.log("enrolling user %s with password %s ...", USER_NAME, USER_PASSWORD);
   // Enroll "admin" which is preregistered in the membersrvc.yaml
   chain.enroll(USER_NAME, USER_PASSWORD, function(err, user) {   
      if (err) {
         console.log("ERROR: failed to enroll user: %s",err);
         process.exit(1);
      }

         invoke(user);
   });
}

// Deploy chaincode
function deploy(user) {
   console.log("deploying chaincode; please wait ...");
   // Construct the deploy request
   var deployRequest = {
       chaincodeName: process.env.CORE_CHAINCODE_ID_NAME,
       fcn: "init",
       args: ["a", "100", "b", "200"]
   };
   // where is the chain code, ignored in dev mode
   deployRequest.chaincodePath = "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02";

   // Issue the deploy request and listen for events
   var tx = user.deploy(deployRequest);
   tx.on('complete', function(results) {
       // Deploy request completed successfully
       console.log("deploy complete; results: %j",results);
       // Set the testChaincodeID for subsequent tests
       chaincodeID = results.chaincodeID;
       invoke(user);
   });
   tx.on('error', function(error) {
       console.log("Failed to deploy chaincode: request=%j, error=%k",deployRequest,error);
       process.exit(1);
   });

}

// Query chaincode
function query(user) {
   console.log("querying chaincode ...");
   // Construct a query request
   var queryRequest = {
      chaincodeID: "5c0e7241354a22bca08f23fa8058ccd7148e03efe562971e2e977fc4003107fd",
      fcn: "query",
      args: ["a"]
   };
   // Issue the query request and listen for events
   var tx = user.query(queryRequest);
   tx.on('complete', function (results) {
      console.log("query completed successfully; results=%j",results);
      process.exit(0);
   });
   tx.on('error', function (error) {
      console.log("Failed to query chaincode: request=%j, error=%k",queryRequest,error);
      process.exit(1);
   });
}

//Invoke chaincode
function invoke(user) {
   console.log("invoke chaincode ...");
   // Construct a query request
   var invokeRequest = {
      chaincodeID: "5c0e7241354a22bca08f23fa8058ccd7148e03efe562971e2e977fc4003107fd",
      fcn: "invoke",
      args: ["a", "b", "2"]
   };
   // Issue the invoke request and listen for events
   var tx = user.invoke(invokeRequest);
   tx.on('submitted', function (results) {
	      console.log("invoke submitted successfully; results=%j",results);	      
	   });   
   tx.on('complete', function (results) {
      console.log("invoke completed successfully; results=%j",results);
      query(user);      
   });
   tx.on('error', function (error) {
      console.log("Failed to invoke chaincode: request=%j, error=%k",invokeRequest,error);
      process.exit(1);
   });
}
