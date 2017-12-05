package ballerina.transactions.participant;

import ballerina.config;

const string participantHost = getParticipantHost();
const int participantPort = getParticipantPort();

function getParticipantHost () returns (string host) {
    host = config:getInstanceValue("http", "participant.host");
    if (host == "") {
        host = "localhost";
    }
    return;
}

function getParticipantPort () returns (int port) {
    var p, e = <int>config:getInstanceValue("http", "participant.port");
    if (e != null) {
        port = 8081;
    } else {
        port = p;
    }
    return;
}
