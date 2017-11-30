package ballerina.transactions.coordinator;

import ballerina.net.http;
import ballerina.util;


enum CoordinationType {
    TWO_PHASE_COMMIT
}

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
}

const string TWO_PHASE_COMMIT = "2pc";

string[] coordinationTypes = [TWO_PHASE_COMMIT];

map coordinationTypeToProtocolsMap = getCoordinationTypeToProtocolsMap();
function getCoordinationTypeToProtocolsMap () returns (map m) {
    m = {};
    string[] values = ["completion", "durable", "volatile"];
    m[TWO_PHASE_COMMIT] = values;
    return;
}

map transactions = {};

transformer <json jsonReq, CreateTransactionContextRequest structReq> toStruct() {
    structReq.coordinationType = validateStrings(jsonReq["coordinationType"]);
    structReq.participantId = validateStrings(jsonReq["participantId"]);
    structReq.participantProtocols = validateProtocols(jsonReq["participantProtocols"]);
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
    basePath:"/",
    host:coordinatorHost,
    port:coordinatorPort
}
service<http> coordinator {

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

                string tid = util:uuid();

                // Add the map of participants for the transaction with ID tid to the transactions map
                transactions[tid] = txn;
                TransactionContext context = {transactionId:tid,
                                                 coordinationType:coordinationType,
                                                 registerAtURL:"http://" + coordinatorHost + ":" + coordinatorPort + "/register"};
                var resPayload, _ = <json>context;
                res.setJsonPayload(resPayload);
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
        path:"/register"
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
            var coordination, _ = (Transaction)transactions[txnId];

            if (coordination == null) {
                respondToBadRequest(res, "Transaction-Unknown. Invalid TID:" + txnId);
            } else if (isRegisteredParticipant(participantId, coordination.participants)) { // Already-Registered
                respondToBadRequest(res,
                                    "Already-Registered. TID:" + txnId + ",participant ID:" + participantId);
            } else if (!protocolCompatible(coordination.coordinationType,
                                           registrationReq.participantProtocols)) { // Invalid-Protocol
                respondToBadRequest(res, "Invalid-Protocol. TID:" + txnId + ",participant ID:" + participantId);
            } else {
                Participant participant = {participantId:participantId,
                                              participantProtocols:registrationReq.participantProtocols,
                                              isInitiator:false};
                coordination.participants[participantId] = participant;

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
            }
            //TODO: Need to handle the  Cannot-Register error case
        }
        _ = res.send();
    }

    resource commitTransaction (http:Request req, http:Response res) {
        //The following command is used to end a micro-transaction successfully,
        // i.e. committing all modifications of all participants. As a result, the coordinator
        // will initiate a prepare() (see section 2.2.5) for each participant.
        //
        //                                                         commit(in: Micro-Transaction-Identifier,
        //                                                         out: ( Committed | Aborted | Mixed )?,
        //                                                         fault: ( Micro-Transaction-Unknown |
        //                                                         Hazard-Outcome ? )
        //
        // The input parameter Micro-Transaction-Identifier is the globally unique identifier of the
        // micro-transaction the participant requests to commit. If the joint outcome is “commit” the output will be
        // Committed. If the joint outcome is “abort”, the output will be Aborted. In case at least one participant
        // performed its commit processing before it had been asked to vote on the joint outcome (e.g. because it was
        // blocking too long) but another participant voted “abort”, no joint outcome can be achieved and Mixed will be
        // the output.

        // If the Micro-Transaction-Identifier is not known to the coordinator, the following fault will be returned.
        // Micro-Transaction-Unknown

        // If at least one of the participants could not end its branch of the micro-transaction as requested
        // (see section 2.2.6), the following fault will be returned:

        // Hazard-Outcome
    }

    resource abortTransaction (http:Request req, http:Response res) {

    }

    resource prepare (http:Request req, http:Response res) {

    }

    resource notify (http:Request req, http:Response res) {

    }

    resource replay (http:Request req, http:Response res) {

    }
}
