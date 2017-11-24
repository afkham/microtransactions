package ballerina.transactions.coordinator;

import ballerina.net.http;
import ballerina.util;

const string TRANSACTION_CONTEXT_VERSION = "1.0";

enum CoordinationType {
    TWO_PHASE_COMMIT
}

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
}

const string TWO_PHASE_COMMIT = "2pc";

string[] coordinationTypes = [TWO_PHASE_COMMIT];

map coordinationTypeToProtocolsMap = getCoordinationTypeToProtocolsMap();
function getCoordinationTypeToProtocolsMap() returns (map m) {
    m = {};
    string[] values = ["completion", "durable", "volatile"];
    m[TWO_PHASE_COMMIT] = values;
    return;
}

map transactions = {};

struct Coordination {
    string coordinationType = "2pc";
    map participants;
}

struct Participant {
    string participantId;
    Protocol[] participantProtocols;
    boolean isInitiator;
}

struct CreateTransactionContextRequest {
    string participantId;
    string coordinationType;
    Protocol[] participantProtocols;
}

struct TransactionContext {
    string contextVersion = "1.0";
    string transactionId;
    string coordinationType;
    string registerAtURL;
}

struct Protocol {
    string name;
    string url;
}

struct RegistrationRequest {
    string transactionId;
    string participantId;
    Protocol[] participantProtocols;
}

struct RegistrationResponse {
    string transactionId;
    Protocol[] coordinatorProtocols;
}

struct RequestError {
    string errorMessage;
}

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
    port:9999
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
                Coordination coordination = {coordinationType:coordinationType};
                coordination.participants = {};

                // Add the initiator, who is also the first participant
                coordination.participants[participant.participantId] = participant;

                string tid = util:uuid();

                // Add the map of participants for the transaction with ID tid to the transactions map
                transactions[tid] = coordination;
                TransactionContext context = {transactionId:tid,
                                                 coordinationType:coordinationType,
                                                 registerAtURL:"http://localhost:9999/register"};
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
        //                                         registerAtURL:"http://localhost:9999/register"};
        //        transactionContexts[tid] = context;
        //        var resPayload, _ = <json>context;
        //        res.setJsonPayload(resPayload);
        //    }
        //}
        res.send();
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

        //TODO: impl
        var registrationReq, e = <RegistrationRequest>req.getJsonPayload();
        if (e != null) {
            res.setStatusCode(400);
            RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        } else {
            string participantId = registrationReq.participantId;
            string transactionId = registrationReq.transactionId;
            var coordination, _ = (Coordination)transactions[transactionId];

            if (coordination == null) { //TODO: replace this with transactions.hasKey(transactionId), Transaction-Unknown
                respondToBadRequest(res, "Transaction-Unknown. Invalid TID:" + transactionId);
            } else if (isRegisteredParticipant(participantId, coordination.participants)) { // Already-Registered
                respondToBadRequest(res,
                                    "Already-Registered. TID:" + transactionId + ",paticipant ID:" + participantId);
            } else if (!protocolCompatible(coordination.coordinationType,
                                           registrationReq.participantProtocols)) { // Invalid-Protocol
                respondToBadRequest(res, "Invalid-Protocol. TID:" + transactionId + ",paticipant ID:" + participantId);
            } else {
                Participant participant = {participantId:participantId,
                                              participantProtocols:registrationReq.participantProtocols,
                                              isInitiator:false};
                coordination.participants[participantId] = participant;
            }
        }
        res.send();
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

function isRegisteredParticipant (string participantId, map participants) returns (boolean) {
    return participants[participantId] != null;
}

function isValidCoordinationType (string coordinationType) returns (boolean) {
    int i = 0;
    int length = lengthof coordinationTypes;
    while (i < length) {
        if (coordinationType == coordinationTypes[i]) {
            return true;
        }
        i = i + 1;
    }
    return false;
}

function protocolCompatible (string coordinationType,
                             Protocol[] participantProtocols) returns (boolean participantProtocolIsValid) {
    var validProtocols, e = (string[])coordinationTypeToProtocolsMap[coordinationType];
    println(e);
    println(coordinationType);
    println(coordinationTypeToProtocolsMap);
    println(validProtocols);

    int i = 0;
    while (i < lengthof participantProtocols) {
        int j = 0;
        while (j < lengthof validProtocols) {
            if (participantProtocols[i].name == validProtocols[j]) {
                participantProtocolIsValid = true;
                break;
            } else {
                participantProtocolIsValid = false;
            }
            j = j + 1;
        }
        if (!participantProtocolIsValid) {
            break;
        }
        i = i + 1;
    }
    return participantProtocolIsValid;
}

function respondToBadRequest (http:Response res, string msg) {
    res.setStatusCode(400);
    RequestError err = {errorMessage:msg};
    var resPayload, _ = <json>err;
    res.setJsonPayload(resPayload);
}


