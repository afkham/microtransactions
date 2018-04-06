import ballerina/io;
import ballerina/log;
import ballerina/math;
import ballerina/http;
import ballerina/runtime;

endpoint http:ServiceEndpoint initiatorEP {
    host:"localhost",
    port:8080
};

string host = "127.0.0.1";
int port = 8889;

@http:ServiceConfig {
    basePath:"/"
}
service InitiatorService bind initiatorEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    init (endpoint conn,http:Request req) {
        http:Response res = new;
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
                io:println("######### sleeping!!!!");
                //runtime:sleepCurrentWorker(100000);
            }
            log:printInfo("$$$$$$$ Before Nested participant transaction");

            transaction {
                log:printInfo("############## Nested participant transaction");
                //abort;
            }
        }
        transaction {
            log:printInfo("2nd initiator transaction");
            //abort;
        }
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to client", err);
            () => log:printInfo("");
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

type BizClientConfig {
string url;
};

type BizClientEP object {
    private {
        http:ClientEndpoint httpClient;
    }

    function init (BizClientConfig conf) {
        endpoint http:ClientEndpoint httpEP {targets:[{url:conf.url}]};
        self.httpClient = httpEP;
    }

    function getClient () returns (BizClient) {
        BizClient client = new;
        client.clientEP = self;
        return client;
    }
};

type BizClient object {
    private {
        BizClientEP clientEP;
    }

    function updateStock(string pathSegment, json bizReq) returns json|error {
        endpoint http:ClientEndpoint httpClient = self.clientEP.httpClient;
        http:Request req = new;
        req.setJsonPayload(bizReq);
        var result = httpClient -> post(pathSegment, req);
        http:Response res = check result;
        log:printInfo("Got response from bizservice");
        json jsonRes = check res.getJsonPayload();
        return jsonRes;
    }
};
