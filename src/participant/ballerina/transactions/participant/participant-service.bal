package ballerina.transactions.participant;

import ballerina.net.http;
import ballerina.util;
import ballerina.log;
import ballerina.caching;

@http:configuration {
    basePath:"/",
    host:participantHost,
    port:participantPort
}
service<http> participantService {
    string participantId = util:uuid();

    caching:Cache stockCache = caching:createCache("stocks", 30000, 10, 0.25);
    map transactions = {};
    map persistentStocks = {};

    resource updateStockQuote (http:Request req, http:Response res) {
        endpoint<TransactionClient> coordinatorEP {
            create TransactionClient();
        }
        var updateReq, _ = <UpdateStockQuoteRequest>req.getJsonPayload();
        string transactionId = updateReq.transactionId;
        string registerAtURL = updateReq.registerAtURL;
        log:printInfo("Update stock quote request received. Transaction: " + transactionId +
                      ", symbol:" + updateReq.symbol + ", price:" + updateReq.price);
        log:printInfo("Registering for transaction: " + transactionId + " with coordinator: " + registerAtURL);
        var j, e = coordinatorEP.register(transactionId, participantId, registerAtURL);
        println(j);
        println(e);

        transactions[transactionId] = transactionId;
        map tmpStocks = {};
        tmpStocks[updateReq.symbol] = updateReq.price;
        stockCache.put(transactionId, tmpStocks);

        json j2 = {"message":"updating stock"};
        res.setJsonPayload(j2);
        _ = res.send();
    }

    resource prepare (http:Request req, http:Response res) {
        var prepareReq, _ = <PrepareRequest>req.getJsonPayload();
        string transactionId = prepareReq.transactionId;
        log:printInfo("Prepare received for transaction: " + transactionId);
        if (transactions[transactionId] == null) {
            res.setStatusCode(404);
            PrepareResponse prepareRes = {message:"Transaction-Unknown"};
            var j, _ = <json>prepareRes;
            res.setJsonPayload(j);
        } else {
            PrepareResponse prepareRes = {message:"prepared"};
            log:printInfo("Prepared");
            var j, _ = <json>prepareRes;
            res.setJsonPayload(j);
        }
        _ = res.send();
    }

    resource notify (http:Request req, http:Response res) {
        var notReq, _ = <NotifyRequest>req.getJsonPayload();
        string transactionId = notReq.transactionId;
        log:printInfo("Notify(" + notReq.message + ") received for transaction: " + transactionId);

        NotifyResponse notifyRes;
        if(transactions[transactionId] == null) {
            res.setStatusCode(404);
            notifyRes = {message:"Transaction-Unknown"};
            var j, _ = <json>notifyRes;
            res.setJsonPayload(j);
        } else {
            if (notReq.message == "commit") {
                notifyRes = {message:"committed"};
                var tmpStocks, _ = (map) stockCache.get(transactionId);
                string[] symbols = tmpStocks.keys();
                int i = 0;
                while(i < lengthof symbols) {
                    persistentStocks[symbols[i]] = tmpStocks[symbols[i]];
                    i = i + 1;
                }
                log:printInfo("Peristed all stocks");
            } else if (notReq.message == "abort") {
                notifyRes = {message:"aborted"};
                stockCache.remove(transactionId);
            }
            transactions.remove(transactionId);
        }
        var j, _ = <json>notifyRes;
        res.setJsonPayload(j);
        _ = res.send();
    }

    resource abortTransaction (http:Request req, http:Response res) {

        _ = res.send();
    }
}
