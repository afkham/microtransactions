import ballerina.math;
import ballerina.net.http;
import ballerina.log;

@http:configuration {
    basePath:"/",
    host:"localhost",
    port:8080
}
service<http> InitiatorService {

    @http:resourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource init (http:Connection conn, http:InRequest req) {
        http:OutResponse res;
        log:printInfo("Initiating transaction...");
        string host = "127.0.0.1";
        int port = 8889;
        transaction {
            boolean successful = callBusinessService("http://" + host + ":" + port + "/stockquote/update", "IBM");
            successful = callBusinessService("http://" + host + ":" + port + "/stockquote/update2", "GOOG");
            if (successful) {
                res = {statusCode:200};
            } else {
                res = {statusCode:500};
            }
        }
        var err = conn.respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back to client", err);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

function callBusinessService (string url, string symbol) returns (boolean successful) {
    endpoint<BizClient> participantEP {
        create BizClient(url);
    }

    float price = math:randomInRange(200, 250) + math:random();
    json bizReq = {symbol:symbol, price:price};
    var _, e = participantEP.updateStock(bizReq);
    if (e != null) {
        successful = false;
    } else {
        successful = true;
    }
    return;
}

public connector BizClient (string url) {

    action updateStock (json bizReq) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient(url, {});
        }
        http:OutRequest req = {};
        req.setJsonPayload(bizReq);
        var res, e = bizEP.post("", req);
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
