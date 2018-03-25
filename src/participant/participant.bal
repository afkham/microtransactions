import ballerina/io;
import ballerina/log;
import ballerina/net.http;

endpoint http:ServiceEndpoint participantEP {
    host:"localhost",
    port:8889
};

struct StockQuoteUpdateRequest {
    string symbol;
    float price;
}

@http:ServiceConfig {
    basePath:"/stockquote"
}
service<http:Service> StockquoteService bind participantEP {

    @http:ResourceConfig {
        path:"/update",
        body: "stockQuoteUpdate"
    }
    updateStockQuote (endpoint conn,http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        log:printInfo("Received update stockquote request");
        http:Response res = {};
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [stockQuoteUpdate.symbol, stockQuoteUpdate.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res.statusCode = 200;
            res.setJsonPayload(jsonRes);
        }
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to initiator", err);
        }
    }

    @http:ResourceConfig {
        path:"/update2",
        body: "stockQuoteUpdate"
    }
    updateStockQuote2 (endpoint conn,http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        log:printInfo("Received update stockquote request2");
        http:Response res = {};
        transaction {
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [stockQuoteUpdate.symbol, stockQuoteUpdate.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res.statusCode = 200;
            res.setJsonPayload(jsonRes);
            //abort;
        }
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to initiator", err);
        }
    }
}

@http:ServiceConfig {
    basePath:"/stockquote2"
}
service<http:Service> StockquoteService2 bind participantEP {

    @http:ResourceConfig {
        path:"/update",
        body: "stockQuoteUpdate"
    }
    updateStockQuote (endpoint conn, http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        log:printInfo("Received update stockquote request");
        http:Response res = {};
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            //if (symbol == "MSFT") {
            //    abort;
            //}
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [stockQuoteUpdate.symbol, stockQuoteUpdate.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res.statusCode = 200;
            res.setJsonPayload(jsonRes);
        }
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to initiator", err);
        }
    }

    @http:ResourceConfig {
        path:"/update2",
        body: "stockQuoteUpdate"
    }
    updateStockQuote2 (endpoint conn, http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        endpoint http:ClientEndpoint participant2EP {
            targets:[{uri:"http://localhost:8890/p2"}]
        };
        log:printInfo("Received update stockquote request2");
        http:Response res = {};
        transaction {
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [stockQuoteUpdate.symbol, stockQuoteUpdate.price]);
            log:printInfo(msg);

            string pathSeqment = io:sprintf("/update/%j/%j", [stockQuoteUpdate.symbol, stockQuoteUpdate.price]);
            var result = participant2EP -> get(pathSeqment, {});
            json jsonRes;
            match result {
                http:Response => {
                    res.statusCode = 200;
                    jsonRes = {"message":"updated stock"};
                }
                http:HttpConnectorError err => {
                    res.statusCode = 500;
                    jsonRes = {"message":"update failed"};
                }
            }
            res.setJsonPayload(jsonRes);
            if (res.statusCode == 500) {
                io:println("###### Call to participant2 unsuccessful Aborting");
                abort;
            }
        }
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to initiator", err);
        }
    }
}
