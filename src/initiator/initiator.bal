import ballerina.math;
import ballerina.net.http;
import ballerina.log;
import ballerina.io;

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
    init (endpoint conn, http:Request req) {
        http:Response res;
        log:printInfo("Initiating transaction...");

        transaction with retries(4) {
            log:printInfo("1st initiator transaction");
            //boolean successful = callBusinessService("/stockquote/update", "IBM");
            //if (!successful) {
            //    res = {statusCode:500};
            //    abort;
            //} else {
                boolean successful = callBusinessService("/stockquote2/update2", "GOOG");
                if (!successful) {
                    log:printInfo("Business service call failed");
                    res = {statusCode:500};
                    abort;
                }
                //    else {
            //        boolean successful = callBusinessService("/stockquote2/update2", "AMZN");
            //        if (!successful) {
            //            io:println("###### Call to participant unsuccessful Aborting");
            //            res = {statusCode:500};
            //            abort;
                    //}
                    //else {
                    //    successful = callBusinessService("/stockquote2/update", "MSFT");
                    //    if (!successful) {
                    //        res = {statusCode:500};
                    //        abort;
                         else {
                            res = {statusCode:200};
                        }
                    //}
                //}
            //}
            transaction {
                log:printInfo("Nested participant transaction");
                //abort;
            }
        }
        //transaction {
        //    log:printInfo("2nd initiator transaction");
        //}
        var err = conn -> respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back to client", err);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

function callBusinessService (string pathSegment, string symbol) returns (boolean successful) {
    endpoint BizClientEP ep {
        url:"http://" + host + ":" + port
    };
    float price = math:randomInRange(200, 250) + math:random();
    json bizReq = {symbol:symbol, price:price};
    var _, e = ep -> updateStock(pathSegment, bizReq);
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

function <BizClientEP ep> init(BizClientConfig conf){
    endpoint http:ClientEndpoint httpEP {targets:[{uri:conf.url}]};
    ep.httpClient = httpEP;
}

function <BizClientEP ep> getClient() returns (BizClient) {
    return {clientEP: ep};
}

struct BizClient {
    BizClientEP clientEP;
}

function<BizClient client> updateStock (string pathSegment, json bizReq) returns (json jsonRes, error err) {
    endpoint http:ClientEndpoint httpClient = client.clientEP.httpClient;
    http:Request req = {};
    req.setJsonPayload(bizReq);
    var res, e = httpClient -> post(pathSegment, req);
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
