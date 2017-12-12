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
        string transactionId = req.getHeader("X-XID");
        string registerAtURL = req.getHeader("X-Register-At-URL");
        log:printInfo("Update stock quote request received. Transaction: " + transactionId +
                      ", symbol:" + updateReq.symbol + ", price:" + updateReq.price);
        log:printInfo("Registering for transaction: " + transactionId + " with coordinator: " + registerAtURL);
        var j, e = coordinatorEP.register(transactionId, participantId, registerAtURL);
        println(j);
        if (e == null) {
            log:printInfo("Registered with coordinator for transaction: " + transactionId);

            TwoPhaseCommitTransaction txn = {transactionId:transactionId, state:TransactionState.ACTIVE};
            transactions[transactionId] = txn;
            map tmpStocks = {};
            tmpStocks[updateReq.symbol] = updateReq.price;
            stockCache.put(transactionId, tmpStocks);

            json jsonRes = {"message":"updating stock"};
            res.setJsonPayload(jsonRes);
        } else {
            log:printErrorCause("Cannot register with coordinator for transaction: " + transactionId, e);
            res.setStatusCode(400);
            json jsonRes = {"message":"Cannot register for transaction: " + transactionId};
            res.setJsonPayload(jsonRes);
        }
        _ = res.send();
    }

    resource prepare (http:Request req, http:Response res) {
        var prepareReq, _ = <PrepareRequest>req.getJsonPayload();
        string transactionId = prepareReq.transactionId;
        log:printInfo("Prepare received for transaction: " + transactionId);
        var txn, _ = (TwoPhaseCommitTransaction)transactions[transactionId];
        if (txn == null) {
            res.setStatusCode(404);
            PrepareResponse prepareRes = {message:"Transaction-Unknown"};
            var j, _ = <json>prepareRes;
            res.setJsonPayload(j);
        } else {
            txn.state = TransactionState.PREPARED;
            //PrepareResponse prepareRes = {message:"read-only"};
            PrepareResponse prepareRes = {message:"prepared"};
            log:printInfo("Prepared");
            var j, _ = <json>prepareRes;
            res.setJsonPayload(j);
        }
        _ = res.send();
    }

    resource notify (http:Request req, http:Response res) {
        var notifyReq, _ = <NotifyRequest>req.getJsonPayload();
        string transactionId = notifyReq.transactionId;
        log:printInfo("Notify(" + notifyReq.message + ") received for transaction: " + transactionId);

        NotifyResponse notifyRes;
        var txn, _ = (TwoPhaseCommitTransaction)transactions[transactionId];
        if (txn == null) {
            res.setStatusCode(404);
            notifyRes = {message:"Transaction-Unknown"};
        } else {
            if (notifyReq.message == "commit") {
                if (txn.state != TransactionState.PREPARED) {
                    res.setStatusCode(400);
                    notifyRes = {message:"Not-Prepared"};
                } else {
                    notifyRes = {message:"committed"};
                    var tmpStocks, _ = (map)stockCache.get(transactionId);
                    string[] symbols = tmpStocks.keys();
                    int i = 0;
                    while (i < lengthof symbols) {
                        persistentStocks[symbols[i]] = tmpStocks[symbols[i]];
                        i = i + 1;
                    }
                    println(persistentStocks);
                    log:printInfo("Persisted all stocks");
                }
            } else if (notifyReq.message == "abort") {
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
        // TODO impl
        _ = res.send();
    }
}
