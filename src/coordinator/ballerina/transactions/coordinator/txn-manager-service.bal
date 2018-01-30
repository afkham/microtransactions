// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package ballerina.transactions.coordinator;

import ballerina.net.http;
import ballerina.log;

enum CoordinationType {
    TWO_PHASE_COMMIT
}
public const string TWO_PHASE_COMMIT = "2pc";

string[] coordinationTypes = [TWO_PHASE_COMMIT];

map coordinationTypeToProtocolsMap = getCoordinationTypeToProtocolsMap();
function getCoordinationTypeToProtocolsMap () returns (map m) {
    m = {};
    string[] twoPhaseCommitProtocols = ["completion", "volatile", "durable"];
    //string[] twoPhaseCommitProtocols = [PROTOCOL_COMPLETION, PROTOCOL_VOLATILE, PROTOCOL_DURABLE];
    m[TWO_PHASE_COMMIT] = twoPhaseCommitProtocols;
    return;
}

@http:configuration {
    basePath:basePath,
    host:coordinatorHost,
    port:coordinatorPort
}
service<http> manager {

    @http:resourceConfig {
        path:"/createContext"
    }
    resource createContext (http:Connection conn, http:InRequest req) {
        var ccReq, e = <CreateTransactionContextRequest>req.getJsonPayload();
        http:OutResponse res;
        if (e != null) {
            log:printErrorCause("Invalid registration request", (error)e);
            println(req.getJsonPayload());
            res = {statusCode:400};
            RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        } else {
            string coordinationType = ccReq.coordinationType;
            if (!isValidCoordinationType(coordinationType)) {
                res = {statusCode:422};
                RequestError err = {errorMessage:"Invalid-Coordination-Type:" + coordinationType};
                var resPayload, _ = <json>err;
                res.setJsonPayload(resPayload);
            } else {
                CreateTransactionContextRequest createContextReq = (CreateTransactionContextRequest)ccReq;
                Transaction txn = createTransaction(coordinationType);
                //TODO: We may not need to make the initiator a participant
                Participant participant = {participantId:createContextReq.participantId,
                                              isInitiator:true};
                txn.participants = {};

                // Add the initiator, who is also the first participant
                txn.participants[participant.participantId] = participant;

                string txnId = txn.transactionId;

                // Add the map of participants for the transaction with ID tid to the transactions map
                transactions[txnId] = txn;
                TransactionContext context = {transactionId:txnId,
                                                 coordinationType:coordinationType,
                                                 registerAtURL:"http://" + coordinatorHost + ":" + coordinatorPort + basePath + registrationPath};
                var resPayload, _ = <json>context;
                res = {statusCode:200};
                res.setJsonPayload(resPayload);
                log:printInfo("Created transaction: " + txnId);
            }
        }
        var connError = conn.respond(res);
        if (connError != null) {
            log:printErrorCause("Sending response for create transaction context request failed", (error)connError);
        }
    }

    @http:resourceConfig {
        path:registrationPath
    }
    resource register (http:Connection conn, http:InRequest req) {
        //register(in: Micro-Transaction-Registration,
        //out: Micro-Transaction-Coordination?,
        //fault: ( Invalid-Protocol |
        //Already-Registered |
        //Cannot-Register |
        //Micro-Transaction-Unknown )? )

        //If the registering participant specified a protocol name not matching the coordination type of the micro-transaction,
        //the following fault is returned:
        //
        //Invalid-Protocol
        //
        //        If the registering participant is already registered to the micro-transaction,
        //the following fault is returned:
        //
        //Already-Registered
        //
        //        If the coordinator already started the end-of-transaction processing for participants of the Durable
        // protocol (see section 3.1.2) of the micro-transaction, the following fault is returned. Note explicitly,
        // that registration for the Durable protocol is allowed while the coordinator is running the end-of-transaction
        // processing for participants of the Volatile protocol (see section 3.1.3).

        // Cannot-Register
        //If the registering participant specified an unknown micro-transaction identifier, the following fault is returned:

        // Micro-Transaction-Unknown

        var registrationReq, e = <RegistrationRequest>req.getJsonPayload();
        http:OutResponse res;
        if (e != null) {
            res = {statusCode:400};
            RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        } else {
            string participantId = registrationReq.participantId;
            string txnId = registrationReq.transactionId;
            var txn, _ = (Transaction)transactions[txnId];

            if (txn == null) {
                res = respondToBadRequest("Transaction-Unknown. Invalid TID:" + txnId);
                var connError = conn.respond(res);
                if (connError != null) {
                    log:printErrorCause("Sending response for register request with null transaction ID failed",
                                        (error)connError);
                }
            } else if (isRegisteredParticipant(participantId, txn.participants)) { // Already-Registered
                res = respondToBadRequest("Already-Registered. TID:" + txnId + ",participant ID:" + participantId);
                var connError = conn.respond(res);
                if (connError != null) {
                    log:printErrorCause("Sending response for register request by already registered participant
                                         for transaction " + txnId + " failed", (error)connError);
                }
            } else if (!protocolCompatible(txn.coordinationType,
                                           registrationReq.participantProtocols)) { // Invalid-Protocol
                res = respondToBadRequest("Invalid-Protocol. TID:" + txnId + ",participant ID:" + participantId);
                var connError = conn.respond(res);
                if (connError != null) {
                    log:printErrorCause("Sending response for register request by participant with invalid protocol
                                         for transaction " + txnId + " failed", (error)connError);
                }
            } else {
                Participant participant = {participantId:participantId,
                                              participantProtocols:registrationReq.participantProtocols,
                                              isInitiator:false};
                txn.participants[participantId] = participant;

                // Send the response
                Protocol[] participantProtocols = registrationReq.participantProtocols;
                Protocol[] coordinatorProtocols = [];
                int i = 0;
                foreach participantProtocol in participantProtocols {
                    Protocol coordinatorProtocol =
                    {name:participantProtocol.name,
                        url:"http://" + coordinatorHost + ":" + coordinatorPort + "/protocol/" + participantProtocol.name};

                    coordinatorProtocols[i] = coordinatorProtocol;
                    i = i + 1;
                }

                RegistrationResponse registrationRes = {transactionId:txnId,
                                                           coordinatorProtocols:coordinatorProtocols};
                var resPayload, _ = <json>registrationRes;
                res = {statusCode:200};
                res.setJsonPayload(resPayload);
                var connError = conn.respond(res);
                if (connError != null) {
                    log:printErrorCause("Sending response for register request for transaction " + txnId +
                                        " failed", (error)connError);
                } else {
                    log:printInfo("Registered participant: " + participantId + " for transaction: " + txnId);
                }
            }
            //TODO: Need to handle the  Cannot-Register error case
        }
    }
}
