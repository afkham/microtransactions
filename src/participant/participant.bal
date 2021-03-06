import ballerina/io;
import ballerina/log;
import ballerina/http;

endpoint http:Listener participantEP {
    host:"localhost",
    port:8889
};

type StockQuoteUpdateRequest {
    string symbol;
    float price;
};

@http:ServiceConfig {
    basePath:"/stockquote"
}
service StockquoteService bind participantEP {

    @http:ResourceConfig {
        path:"/update",
        body: "stockQuoteUpdate"
    }
    updateStockQuote (endpoint conn,http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        log:printInfo("Received update stockquote request");
        http:Response res = new;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    untaint stockQuoteUpdate.symbol, untaint stockQuoteUpdate.price);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res.statusCode = 200;
            res.setJsonPayload(jsonRes);
        }
        var result = conn -> respond(res);
        match result {
            error err => log:printError("Could not send response back to initiator", err = err);
            () => log:printInfo("");
        }
    }

    @http:ResourceConfig {
        path:"/update2",
        body: "stockQuoteUpdate"
    }
    updateStockQuote2 (endpoint conn,http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        log:printInfo("Received update stockquote request2");
        http:Response res = new;
        transaction {
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    untaint stockQuoteUpdate.symbol, untaint stockQuoteUpdate.price);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res.statusCode = 200;
            res.setJsonPayload(jsonRes);
            //abort;
        }
        var result = conn -> respond(res);
        match result {
            error err => log:printError("Could not send response back to initiator", err = err);
            () => log:printInfo("");
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
        http:Response res = new;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            //if (symbol == "MSFT") {
            //    abort;
            //}
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    untaint stockQuoteUpdate.symbol, untaint stockQuoteUpdate.price);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res.statusCode = 200;
            res.setJsonPayload(jsonRes);
        }
        var result = conn -> respond(res);
        match result {
            error err => log:printError("Could not send response back to initiator", err = err);
            () => log:printInfo("");
        }
    }

    // @http:ResourceConfig {
    // path:"/passthru",
    // body: "stockQuoteUpdate"
    // }
    // passthru (endpoint conn, http:Request req) {
    //     endpoint http:Client ep {
    //         targets: [{uri: "http://localhost:8890/p2"}]
    //     };
    //     http:Request newReq = {};
    //     var forwardResult = ep -> forward("/task1", req);
    //     match forwardResult {
    //         error err => {
    //             io:print("Participant1 could not send get request to participant2/task1. Error:");
    //             sendErrorResponseToInitiator(conn);
    //         }
    //         http:Response forwardRes => {
    //             var forwardRes2 = conn -> forward(getRes);
    //             match forwardRes2 {
    //                 error err => {
    //                     io:print("Participant1 could not forward response from participant2 to initiator. Error:");
    //                     io:println(err);
    //                 }
    //                 null => io:print("");
    //             }
    //         }
    // }

    @http:ResourceConfig {
        path:"/update2",
        body: "stockQuoteUpdate"
    }
    updateStockQuote2 (endpoint conn, http:Request req, StockQuoteUpdateRequest stockQuoteUpdate) {
        endpoint http:Client participant2EP {
            url:"http://localhost:8890/p2"
        };
        log:printInfo("Received update stockquote request2");
        http:Response res = new;
        transaction {
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    untaint stockQuoteUpdate.symbol, untaint stockQuoteUpdate.price);
            log:printInfo(msg);

            string pathSeqment = io:sprintf("/update/%j/%j", untaint stockQuoteUpdate.symbol, untaint stockQuoteUpdate.price);
            var result = participant2EP -> get(pathSeqment);
            json jsonRes;
            match result {
                http:Response => {
                    res.statusCode = 200;
                    jsonRes = {"message":"updated stock"};
                }
                error err => {
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
        var result2 = conn -> respond(res);
        match result2 {
            error err => log:printError("Could not send response back to initiator", err = err);
            () => log:printInfo("");
        }
    }
}
