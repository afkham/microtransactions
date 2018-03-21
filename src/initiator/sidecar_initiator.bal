import ballerina.io;
import ballerina.log;
import ballerina.math;
import ballerina.net.http;

endpoint http:ServiceEndpoint initiatorEP {
    host:"localhost",
    port:8081
};

string host = "10.100.5.131";
int port = 8080;

@http:ServiceConfig {
    basePath:"/"
}
service<http:Service> InitiatorService bind initiatorEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    init (endpoint conn,http:Request req) {
        http:Response res;
        log:printInfo("Initiating transaction...");

        transaction with retries(4) {
            log:printInfo("1st initiator transaction");
            boolean successful = callBusinessService("/reservation/hotel");
            if (!successful) {
                res = {statusCode:500};
                abort;
            } else {
                res = {statusCode:200};
            }
        }
        var err = conn -> respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back to client", err);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

function callBusinessService (string pathSegment) returns (boolean successful) {
    endpoint BizClientEP ep {
        url:"http://" + host + ":" + port
    };
    float price = math:randomInRange(200, 250) + math:random();
    var _, e = ep -> call(pathSegment);
    if (e != null) {
        successful = false;
    } else {
        successful = true;
    }
    return;
}

// BizClient connector

struct BizClientConfig {
    string url;
}

struct BizClientEP {
    http:ClientEndpoint httpClient;
}

function <BizClientEP ep> init (BizClientConfig conf) {
    endpoint http:ClientEndpoint httpEP {targets:[{uri:conf.url}]};
    ep.httpClient = httpEP;
}

function <BizClientEP ep> getClient () returns (BizClient) {
    return {clientEP:ep};
}

struct BizClient {
    BizClientEP clientEP;
}

function <BizClient client> call (string pathSegment) returns (json jsonRes, error err) {
    endpoint http:ClientEndpoint httpClient = client.clientEP.httpClient;
    http:Request req = {};
    var res, e = httpClient -> get(pathSegment, req);
    log:printInfo("Got response from bizservice");
    if (e == null) {
        if (res.statusCode != 200) {
            err = {message:"Error occurred"};
        } else {
            jsonRes, _ = res.getJsonPayload();
        }
    } else {
        err = (error)e;
    }
    return;
}
