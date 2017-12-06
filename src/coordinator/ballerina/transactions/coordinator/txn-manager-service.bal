package ballerina.transactions.coordinator;

import ballerina.net.http;
import ballerina.util;

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

transformer <json jsonReq, CreateTransactionContextRequest structReq> toStruct() {
    structReq.coordinationType = validateStrings(jsonReq["coordinationType"]);
    structReq.participantId = validateStrings(jsonReq["participantId"]);
    //structReq.participantProtocols = validateProtocols(jsonReq["participantProtocols"]);
}

function validateStrings (json j) returns (string) {
    if (j == null) {
        error e = {msg:"Invalid data"};
        throw e;
    }
    var result, _ = (string)j;
    return result;
}

function validateProtocols (json j) returns (Protocol[]) {
    if (j == null) {
        error e = {msg:"Invalid data"};
        throw e;
    }
    Protocol[] protocols = [];
    int i = 0;
    while (i < lengthof j) {
        json protocolJson = j[i];
        Protocol protocol = {name:protocolJson["name"].toString(), url:protocolJson["url"].toString()};
        protocols[i] = protocol;
        i = i + 1;
    }
    return protocols;
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
    resource createContext (http:Request req, http:Response res) {
        try {
            CreateTransactionContextRequest ccReq = <CreateTransactionContextRequest, toStruct()>req.getJsonPayload();
            string coordinationType = ccReq.coordinationType;
            if (!isValidCoordinationType(coordinationType)) {
                res.setStatusCode(422);
                RequestError err = {errorMessage:"Invalid-Coordination-Type:" + coordinationType};
                var resPayload, _ = <json>err;
                res.setJsonPayload(resPayload);
            } else {
                CreateTransactionContextRequest createContextReq = (CreateTransactionContextRequest)ccReq;
                Participant participant = {participantId:createContextReq.participantId,
                                              participantProtocols:createContextReq.participantProtocols,
                                              isInitiator:true};
                Transaction txn = {coordinationType:coordinationType};
                txn.participants = {};

                // Add the initiator, who is also the first participant
                txn.participants[participant.participantId] = participant;

                string txnId = util:uuid();

                // Add the map of participants for the transaction with ID tid to the transactions map
                transactions[txnId] = txn;
                TransactionContext context = {transactionId:txnId,
                                                 coordinationType:coordinationType,
                                                 registerAtURL:"http://" + coordinatorHost + ":" + coordinatorPort + basePath + registrationPath};
                var resPayload, _ = <json>context;
                res.setJsonPayload(resPayload);
                println("Created transaction " + txnId);
            }
        } catch (error e) {
            res.setStatusCode(400);
            RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        }
        //CreateTransactionContextRequest ccReq = <CreateTransactionContextRequest>req.getJsonPayload();
        //if (e != null) {
        //    res.setStatusCode(400);
        //    RequestError err = {errorMessage:"Bad Request"};
        //    var resPayload, _ = <json>err;
        //    res.setJsonPayload(resPayload);
        //} else {
        //    string coordinationType = ccReq.coordinationType;
        //    if (!isValidCoordinationType(coordinationType)) {
        //        res.setStatusCode(422);
        //        RequestError err = {errorMessage:"Invalid-Coordination-Type:" + coordinationType};
        //        var resPayload, _ = <json>err;
        //        res.setJsonPayload(resPayload);
        //    } else {
        //        CreateTransactionContextRequest createContextReq = (CreateTransactionContextRequest)ccReq;
        //        Participant participant = {participantId:createContextReq.participantId,
        //                                      participantProtocols:createContextReq.participantProtocols,
        //                                      isInitiator:true};
        //        map transactionParticipants = {};
        //        // Add the initiator, who is also the first participant
        //        transactionParticipants[participant.participantId] = participant;
        //
        //        string tid = util:uuid();
        //
        //        // Add the map of participants for the transaction with ID tid to the transactions map
        //        transactions[tid] = transactionParticipants;
        //        TransactionContext context = {transactionId:tid,
        //                                         coordinationType:coordinationType,
        //                                         registerAtURL:"http://"+ coordinatorHost + ":" + coordinatorPort + "/register"};
        //        transactionContexts[tid] = context;
        //        var resPayload, _ = <json>context;
        //        res.setJsonPayload(resPayload);
        //    }
        //}
        _ = res.send();
    }

    @http:resourceConfig {
        path: registrationPath
    }
    resource register (http:Request req, http:Response res) {
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
        if (e != null) {
            res.setStatusCode(400);
            RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        } else {
            string participantId = registrationReq.participantId;
            string txnId = registrationReq.transactionId;
            var txn, _ = (Transaction)transactions[txnId];

            if (txn == null) {
                respondToBadRequest(res, "Transaction-Unknown. Invalid TID:" + txnId);
            } else if (isRegisteredParticipant(participantId, txn.participants)) { // Already-Registered
                respondToBadRequest(res,
                                    "Already-Registered. TID:" + txnId + ",participant ID:" + participantId);
            } else if (!protocolCompatible(txn.coordinationType,
                                           registrationReq.participantProtocols)) { // Invalid-Protocol
                respondToBadRequest(res, "Invalid-Protocol. TID:" + txnId + ",participant ID:" + participantId);
            } else {
                Participant participant = {participantId:participantId,
                                              participantProtocols:registrationReq.participantProtocols,
                                              isInitiator:false};
                txn.participants[participantId] = participant;

                print("=========");
                println(txn.participants);
                print("+++++++++");
                println(transactions[txnId]);

                // Send the response
                Protocol[] participantProtocols = registrationReq.participantProtocols;
                Protocol[] coordinatorProtocols = [];
                int i = 0;
                while (i < lengthof participantProtocols) {
                    Protocol participantProtocol = participantProtocols[i];
                    Protocol coordinatorProtocol =
                    {name:participantProtocol.name,
                        url:"http://" + coordinatorHost + ":" + coordinatorPort + "/protocol/" + participantProtocol.name};

                    coordinatorProtocols[i] = coordinatorProtocol;
                    i = i + 1;
                }

                RegistrationResponse registrationRes = {transactionId:txnId,
                                                           coordinatorProtocols:coordinatorProtocols};
                var resPayload, _ = <json>registrationRes;
                res.setJsonPayload(resPayload);
                println("Registered participant " + participantId + " for transaction " + txnId);
            }
            //TODO: Need to handle the  Cannot-Register error case
        }
        _ = res.send();
    }
}
