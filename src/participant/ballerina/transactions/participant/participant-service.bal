package ballerina.transactions.participant;

import ballerina.net.http;

@http:configuration {
    basePath:"/",
    host:participantHost,
    port:participantPort
}
service<http> participantService {

    resource prepare (http:Request req, http:Response res) {

    }

    resource notify (http:Request req, http:Response res) {

    }
}
