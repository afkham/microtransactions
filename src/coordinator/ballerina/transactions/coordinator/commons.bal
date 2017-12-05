package ballerina.transactions.coordinator;

import ballerina.net.http;

const string TRANSACTION_CONTEXT_VERSION = "1.0";

public map transactions = {};

enum TransactionState {
    PREPARED, COMMITTED, ABORTED
}

public struct Transaction {
    string coordinationType = "2pc";
    TransactionState state;
    map participants;
}

public struct Participant {
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

public struct Protocol {
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

public function respondToBadRequest (http:Response res, string msg) {
    res.setStatusCode(400);
    RequestError err = {errorMessage:msg};
    var resPayload, _ = <json>err;
    res.setJsonPayload(resPayload);
}
