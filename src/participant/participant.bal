import ballerina.log;
import ballerina.io;
import ballerina.net.http;

@http:configuration {
    basePath:"/stockquote",
    host:"localhost",
    port:8889
}
service<http> StockquoteService {

    @http:resourceConfig {
        path:"/update"
    }
    resource updateStockQuote (http:Connection conn, http:InRequest req) {
        log:printInfo("Received update stockquote request");
        http:OutResponse res;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            json updateReq = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
            var err = conn.respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }

    @http:resourceConfig {
        path:"/update2"
    }
    resource updateStockQuote2 (http:Connection conn, http:InRequest req) {
        log:printInfo("Received update stockquote request2");
        http:OutResponse res;
        transaction {
            json updateReq = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
            var err = conn.respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }
}

@http:configuration {
    basePath:"/stockquote2",
    host:"localhost",
    port:8889
}
service<http> StockquoteService2 {

    @http:resourceConfig {
        path:"/update"
    }
    resource updateStockQuote (http:Connection conn, http:InRequest req) {
        log:printInfo("Received update stockquote request");
        http:OutResponse res;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            json updateReq = req.getJsonPayload();
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
            var err = conn.respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }

    @http:resourceConfig {
        path:"/update2"
    }
    resource updateStockQuote2 (http:Connection conn, http:InRequest req) {
        endpoint<http:HttpClient> participant2EP {
            create http:HttpClient("http://localhost:8890/p2", {});
        }
        log:printInfo("Received update stockquote request2");
        http:OutResponse res;
        transaction {
            json updateReq = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);


            string pathSeqment = io:sprintf("/update/%j/%j", [updateReq.symbol, updateReq.price]);
            var inRes, e = participant2EP.get(pathSeqment, {});
            json jsonRes;
            if(e == null) {
                res = {statusCode:200};
                jsonRes = {"message":"updated stock"};
            } else {
                res = {statusCode:500};
                jsonRes = {"message":"update failed"};
            }

            res.setJsonPayload(jsonRes);
            var err = conn.respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }
}
