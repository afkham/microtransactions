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

package participant;

import ballerina.caching;
import ballerina.transactions.coordinator;
import ballerina.log;
import ballerina.net.http;
import ballerina.util;
import ballerina.config;

@http:configuration {
    basePath:"/stockquote",
    host:participantHost,
    port:participantPort
}
service<http> stockquoteService {
    string participantId = util:uuid();

    caching:Cache stockCache = caching:createCache("stocks", 30000, 10, 0.25);
    map persistentStocks = {};

    @http:resourceConfig {
        path:"/update"
    }
    resource updateStockQuote (http:Connection conn, http:InRequest req) {

        println("Received update stockquote request");
        http:OutResponse res;
        var updateReq, _ = <UpdateStockQuoteRequest>req.getJsonPayload();
        string transactionId = req.getHeader("X-XID");
        string registerAtURL = req.getHeader("X-Register-At-URL");

        var txnCtx, err = coordinator:beginTransaction(transactionId, registerAtURL, "2pc");
        println("Registered for transaction:" + txnCtx.transactionId);
        log:printInfo("Update stock quote request received. Transaction: " + transactionId +
                      ", symbol:" + updateReq.symbol + ", price:" + updateReq.price);

        var msg, endTxnErr = coordinator:endTransaction(txnCtx.transactionId);

        //sleep(5000);
        //// Update local data
        //TwoPhaseCommitTransaction txn = {transactionId:transactionId, state:TransactionState.ACTIVE};
        //transactions[transactionId] = txn;
        //map tmpStocks = {};
        //tmpStocks[updateReq.symbol] = updateReq.price;
        //stockCache.put(transactionId, tmpStocks);
        //
        //// Call another participant
        //if (getParticipantPort() != 10000) {
        //    var j, err = participantEP.updateStock(transactionId, registerAtURL, updateReq, "localhost", 10000);
        //    if (err != null) {
        //        j, err = coordinatorEP.abortTransaction({transactionId:transactionId});
        //
        //        json jsonRes = {"message":"Could not call participant"};
        //        res = {statusCode:500};
        //        res.setJsonPayload(jsonRes);
        //        _ = conn.respond(res);
        //        return;
        //    }
        //}

        json jsonRes = {"message":"updating stock"};
        res = {statusCode:200};
        res.setJsonPayload(jsonRes);
        _ = conn.respond(res);
    }
}

struct UpdateStockQuoteRequest {
    string symbol;
    float price;
}

const string participantHost = getParticipantHost();
const int participantPort = getParticipantPort();

function getParticipantHost () returns (string host) {
    host = config:getInstanceValue("http", "participant.host");
    if (host == "") {
        host = "localhost";
    }
    return;
}

function getParticipantPort () returns (int port) {
    var p, e = <int>config:getInstanceValue("http", "participant.port");
    if (e != null) {
        port = 8081;
    } else {
        port = p;
    }
    return;
}
