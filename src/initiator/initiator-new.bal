import ballerina/io;
import ballerina/log;
import ballerina/net.http;

endpoint http:ServiceEndpoint initiatorEP {
    host:"localhost",
    port:8080
};

string host = "127.0.0.1";
int port = 8889;

@http:ServiceConfig {
    basePath:"/"
}
service<http:Service> InitiatorService bind initiatorEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    init (endpoint conn,http:Request req) {
        http:Response res = {statusCode:200};
        log:printInfo("Initiating transaction...");

        transaction {
            log:printInfo("1st initiator transaction");

        }
        _ = conn -> respond(res);
    }
}
