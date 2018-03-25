import ballerina/io;
import ballerina/log;
import ballerina/math;
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
        http:Response res = {};
        log:printInfo("Initiating transaction...");

        transaction {
            log:printInfo("1st initiator transaction");
            boolean successful = callBusinessService("/stockquote/update", "IBM");
            if (!successful) {
                res.statusCode = 500;
                abort;
            } else {
                successful = callBusinessService("/stockquote/update2", "GOOG");
                if (!successful) {
                    log:printInfo("Business service call failed");
                    res.statusCode = 500;
                    abort;
                } else {
                    successful = callBusinessService("/stockquote2/update2", "AMZN");
                    if (!successful) {
                        io:println("###### Call to participant unsuccessful Aborting");
                        res.statusCode = 500;
                        abort;
                    } else {
                        successful = callBusinessService("/stockquote2/update", "MSFT");
                        if (!successful) {
                            res.statusCode = 500;
                            abort;
                        } else {
                            res.statusCode = 200;
                        }
                    }
                }
            }
            log:printInfo("$$$$$$$ Before Nested participant transaction");

            transaction {
                log:printInfo("############## Nested participant transaction");
                abort;
            }
        }
        //transaction {
        //    log:printInfo("2nd initiator transaction");
        //}
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to client", err);
        }
    }
}

function callBusinessService (string pathSegment, string symbol) returns boolean {
    endpoint BizClientEP ep {
        url:"http://" + host + ":" + port
    };
    float price = math:randomInRange(200, 250) + math:random();
    json bizReq = {symbol:symbol, price:price};
    var result = ep -> updateStock(pathSegment, bizReq);
    match result {
        error => return false;
        json => return true;
    }
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

function <BizClient client> updateStock (string pathSegment, json bizReq) returns json|error {
    endpoint http:ClientEndpoint httpClient = client.clientEP.httpClient;
    http:Request req = {};
    req.setJsonPayload(bizReq);
    http:Response res =? httpClient -> post(pathSegment, req);
    log:printInfo("Got response from bizservice");
    json jsonRes =? res.getJsonPayload();
    return jsonRes;
}
