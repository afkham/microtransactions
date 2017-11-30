package ballerina.transactions.coordinator;

import ballerina.config;

const string coordinatorHost = getCoordinatorHost();
const int coordinatorPort = getCoordinatorPort();

function getCoordinatorHost () returns (string host) {
    host = config:getInstanceValue("http", "coordinator.host");
    if (host == "") {
        host = "localhost";
    }
    return;
}

function getCoordinatorPort () returns (int port) {
    var p, e = <int>config:getInstanceValue("http", "coordinator.port");
    if (e != null) {
        port = 8080;
    } else {
        port = p;
    }
    return;
}
