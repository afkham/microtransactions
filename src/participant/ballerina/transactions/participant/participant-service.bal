// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

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

    resource updateStockQuote (http:Connection conn, http:InRequest req) {
        endpoint<TransactionClient> coordinatorEP {
            create TransactionClient();
        }
        http:OutResponse res;
        var updateReq, _ = <UpdateStockQuoteRequest>req.getJsonPayload();
        string transactionId = req.getHeader("X-XID").value;
        string registerAtURL = req.getHeader("X-Register-At-URL").value;
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
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
        } else {
            log:printErrorCause("Cannot register with coordinator for transaction: " + transactionId, e);
            res = {statusCode:400};
            json jsonRes = {"message":"Cannot register for transaction: " + transactionId};
            res.setJsonPayload(jsonRes);
        }
        _ = conn.respond(res);
    }

    resource prepare (http:Connection conn, http:InRequest req) {
        http:OutResponse res;
        var prepareReq, _ = <PrepareRequest>req.getJsonPayload();
        string transactionId = prepareReq.transactionId;
        log:printInfo("Prepare received for transaction: " + transactionId);
        var txn, _ = (TwoPhaseCommitTransaction)transactions[transactionId];
        if (txn == null) {
            res = {statusCode:404};
            PrepareResponse prepareRes = {message:"Transaction-Unknown"};
            var j, _ = <json>prepareRes;
            res.setJsonPayload(j);
        } else {
            res = {statusCode:200};
            txn.state = TransactionState.PREPARED;
            //PrepareResponse prepareRes = {message:"read-only"};
            PrepareResponse prepareRes = {message:"prepared"};
            log:printInfo("Prepared");
            var j, _ = <json>prepareRes;
            res.setJsonPayload(j);
        }
        _ = conn.respond(res);
    }

    resource notify (http:Connection conn, http:InRequest req) {
        var notifyReq, _ = <NotifyRequest>req.getJsonPayload();
        string transactionId = notifyReq.transactionId;
        log:printInfo("Notify(" + notifyReq.message + ") received for transaction: " + transactionId);
        http:OutResponse res;

        NotifyResponse notifyRes;
        var txn, _ = (TwoPhaseCommitTransaction)transactions[transactionId];
        if (txn == null) {
            res = {statusCode:404};
            notifyRes = {message:"Transaction-Unknown"};
        } else {
            if (notifyReq.message == "commit") {
                if (txn.state != TransactionState.PREPARED) {
                    res = {statusCode:400};
                    notifyRes = {message:"Not-Prepared"};
                } else {
                    res = {statusCode:200};
                    notifyRes = {message:"committed"};
                    var tmpStocks, _ = (map)stockCache.get(transactionId);
                    string[] symbols = tmpStocks.keys();
                    foreach symbol in symbols {
                        persistentStocks[symbol] = tmpStocks[symbol];
                    }
                    println(persistentStocks);
                    log:printInfo("Persisted all stocks");
                }
            } else if (notifyReq.message == "abort") {
                res = {statusCode:200};
                notifyRes = {message:"aborted"};
                stockCache.remove(transactionId);
            }
            transactions.remove(transactionId);
        }
        var j, _ = <json>notifyRes;
        res.setJsonPayload(j);
        _ = conn.respond(res);
    }

    resource abortTransaction (http:Connection conn, http:InRequest req) {
        // TODO impl
        http:OutResponse res = {};
        _ = conn.respond(res);
    }
}
