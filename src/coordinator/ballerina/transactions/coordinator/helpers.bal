package ballerina.transactions.coordinator;

import ballerina.net.http;

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

function respondToBadRequest (http:Response res, string msg) {
    res.setStatusCode(400);
    RequestError err = {errorMessage:msg};
    var resPayload, _ = <json>err;
    res.setJsonPayload(resPayload);
}

function getCoordinationFunction (string coordinationType) returns (function (map) returns (boolean) f) {
    if (coordinationType == TWO_PHASE_COMMIT) {
        f = twoPhaseCommit;
    } else {
        error e = {msg: "Unknown coordination type: " + coordinationType};
        throw e;
    }
    return;
}
