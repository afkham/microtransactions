import ballerina.log;
import ballerina.io;
import ballerina.net.http;

endpoint http:ServiceEndpoint participantEP {
    host:"localhost",
    port:8889
};

@http:ServiceConfig {
    basePath:"/stockquote"
}
service<http:Service> StockquoteService bind participantEP {

    @http:ResourceConfig {
        path:"/update"
    }
    updateStockQuote (endpoint conn, http:Request req) {
        log:printInfo("Received update stockquote request");
        http:Response res;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            var updateReq, _ = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
            var err = conn -> respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }

    @http:ResourceConfig {
        path:"/update2"
    }
    updateStockQuote2 (endpoint conn, http:Request req) {
        log:printInfo("Received update stockquote request2");
        http:Response res;
        transaction {
            var updateReq, _ = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
            var err = conn -> respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
            //abort;
        }
    }
}

@http:ServiceConfig {
    basePath:"/stockquote2"
}
service<http:Service> StockquoteService2 bind participantEP {

    @http:ResourceConfig {
        path:"/update"
    }
    updateStockQuote (endpoint conn, http:Request req) {
        log:printInfo("Received update stockquote request");
        http:Response res;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            var updateReq, _ = req.getJsonPayload();
            var symbol, _ = (string)updateReq.symbol;
            //if (symbol == "MSFT") {
            //    abort;
            //}
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [symbol, updateReq.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
            var err = conn -> respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }

    @http:ResourceConfig {
        path:"/update2"
    }
    updateStockQuote2 (endpoint conn, http:Request req) {
        endpoint http:ClientEndpoint participant2EP {
            targets:[{uri:"http://localhost:8890/p2"}]
        };
        log:printInfo("Received update stockquote request2");
        http:Response res;
        transaction {
            var updateReq, _ = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);


            string pathSeqment = io:sprintf("/update/%j/%j", [updateReq.symbol, updateReq.price]);
            var inRes, e = participant2EP -> get(pathSeqment, {});
            json jsonRes;
            if(e == null) {
                res = {statusCode:200};
                jsonRes = {"message":"updated stock"};
            } else {
                res = {statusCode:500};
                jsonRes = {"message":"update failed"};
            }

            res.setJsonPayload(jsonRes);
            var err = conn -> respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
            if(res.statusCode == 500) {
                io:println("###### Call to participant2 unsuccessful Aborting");
                abort;
            }
        }
    }
}
