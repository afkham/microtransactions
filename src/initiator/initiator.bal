import ballerina.math;
import ballerina.net.http;
import ballerina.log;

@http:configuration {
    basePath:"/",
    host:"localhost",
    port:8080
}
service<http> InitiatorService {

    string host = "127.0.0.1";
    int port = 8889;
    BizClient client = create BizClient("http://" + host + ":" + port);

    @http:resourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource init (http:Connection conn, http:InRequest req) {
        http:OutResponse res;
        log:printInfo("Initiating transaction...");

        transaction with retries(4) {
            log:printInfo("1st initiator transaction");
            boolean successful = callBusinessService(client, "/stockquote/update", "IBM");
            successful = callBusinessService(client, "/stockquote/update2", "GOOG");
            successful = callBusinessService(client, "/stockquote2/update", "AMZN");
            successful = callBusinessService(client, "/stockquote2/update2", "MSFT");
            if (successful) {
                res = {statusCode:200};
            } else {
                res = {statusCode:500};
            }
            transaction {
                log:printInfo("Nested initiator transaction");
            }
        }
        transaction {
            log:printInfo("2nd initiator transaction");
        }
        var err = conn.respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back to client", err);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

function callBusinessService (BizClient client, string pathSegment, string symbol) returns (boolean successful) {
    endpoint<BizClient> participantEP {
        client;
    }
    float price = math:randomInRange(200, 250) + math:random();
    json bizReq = {symbol:symbol, price:price};
    var _, e = participantEP.updateStock(pathSegment, bizReq);
    if (e != null) {
        successful = false;
    } else {
        successful = true;
    }
    return;
}

public connector BizClient (string url) {
    endpoint<http:HttpClient> bizEP {
        create http:HttpClient(url, {});
    }
    action updateStock (string pathSegment, json bizReq) returns (json jsonRes, error err) {
        http:OutRequest req = {};
        req.setJsonPayload(bizReq);
        var res, e = bizEP.post(pathSegment, req);
        log:printInfo("Got response from bizservice");
        if (e == null) {
            if (res.statusCode != 200) {
                err = {message:"Error occurred"};
            } else {
                jsonRes = res.getJsonPayload();
            }
        } else {
            err = (error)e;
        }
        return;
    }
}
