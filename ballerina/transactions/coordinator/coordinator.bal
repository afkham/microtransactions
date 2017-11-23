package ballerina.transactions.coordinator;

import ballerina.net.http;
import ballerina.util;
import ballerina.log;

public const string TRANSACTION_CONTEXT_VERSION = "1.0";

enum CoordinationType {
    TWO_PHASE_COMMIT
}

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
}

const string TWO_PHASE_COMMIT = "2pc";
map coordTypeToProtocolsMap = {TWO_PHASE_COMMIT:[Protocols.COMPLETION, Protocols.DURABLE, Protocols.VOLATILE]};


map transactions = {};

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

map transactionContexts = {};

@http:configuration {
    basePath:"/",
    port:9999
}
service<http> coordinator {

    @http:resourceConfig {
        path:"/createContext"
    }
    resource createContext (http:Request req, http:Response res) {
        //create-context(in: Name-of-Coordination-Type,
        //out: Micro-Transaction-Context?,
        //fault: Invalid-Coordination-Type? )

        //If the name of the coordination type is unknown to the coordinator, the following fault is returned:
        //
        //Invalid-Coordination-Type
        var ccReq, e = <CreateTransactionContextRequest>req.getJsonPayload();
        string coordinationType = ccReq.coordinationType;
        if (coordinationType != TWO_PHASE_COMMIT) { // Only 2PC is supported at the moment
            res.setStatusCode(422);
            RequestError err = {errorMessage:"Invalid-Coordination-Type" + coordinationType};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        } else {

            // Save the participant
            if (e == null) {
                CreateTransactionContextRequest createContextReq = (CreateTransactionContextRequest)ccReq;
                Participant participant = {participantId:createContextReq.participantId,
                                              participantProtocols:createContextReq.participantProtocols,
                                              isInitiator:true};
                map transactionParticipants = {};
                // Add the initiator, who is also the first participant
                transactionParticipants[participant.participantId] = participant;

                string tid = util:uuid();

                // Add the map of participants for the transaction with ID tid to the transactions map
                transactions[tid] = transactionParticipants;

                TransactionContext context = {transactionId:tid,
                                                 coordinationType:coordinationType,
                                                 registerAtURL:"http://localhost:9999/register"};
                transactionContexts[tid] = context;
                var resPayload, _ = <json>context;
                res.setJsonPayload(resPayload);
            } else {
                res.setStatusCode(400);
                RequestError err = {errorMessage:"Bad Request " + coordinationType};
                var resPayload, _ = <json>err;
                res.setJsonPayload(resPayload);
            }
        }
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
        var regRequest, e = <RegistrationRequest>req.getJsonPayload();
        if (e == null) {
            print("X");
        } else {
            log:printErrorCause("Invalid registration request", (error)e);
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
