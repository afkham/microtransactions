import ballerina/log;
import ballerina/io;
import ballerina/math;
import ballerina/net.http;

endpoint http:ServiceEndpoint initiatorEP {
    host:"localhost",
    port:8081
};

endpoint BizClientEP ep {
    url:"http://" + host + ":" + port
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
    init (endpoint conn, http:Request req) {
        http:Response res = {};
        log:printInfo("Initiating transaction...");

        //{"fullName":"Hotel_Marriot2", "checkIn":"Hotel_Marriot_Reserved!", "checkOut":"Hotel_Marriot_Reserved!"}

        transaction with retries = 4 {
            log:printInfo("1st initiator transaction");
            boolean successful = callBusinessService("/reservation/hotel");

            io:println("++++++++++ successful=" + successful);

            if (!successful) {
                res.statusCode = 500;
                abort;
            } else {
                res.statusCode = 200;
            }
        }
        var result = conn -> respond(res);
        match result {
            error err => log:printErrorCause("Could not send response back to client", err);
            null => log:printInfo("Sent response back to client");
        }
    }
}

function callBusinessService (string pathSegment) returns boolean { // successful
    float price = math:randomInRange(200, 250) + math:random();
    var result = ep -> call(pathSegment);
    match result {
        json => return true;
        error err => {
            io:println(err);
            return false;
        }

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

function <BizClient client> call (string pathSegment) returns json|error { //json jsonRes, error err
    endpoint http:ClientEndpoint httpClient = client.clientEP.httpClient;
    http:Request req = {};
    json payload = {fullName:"Hotel_Marriot33", checkIn:"Hotel_Marriot_Reserved!",
                       checkOut:"Hotel_Marriot_Reserved!"};
    req.setJsonPayload(payload);
    http:Response res =? httpClient -> post(pathSegment, req);
    log:printInfo("Got response from bizservice");
    io:println(res);
    if (res.statusCode != 200) {
        error err = {message:"Error occurred"};
        return err;
    } else {
        json jsonRes =? res.getJsonPayload();
        return jsonRes;
    }
}
