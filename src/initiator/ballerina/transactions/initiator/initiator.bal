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

package ballerina.transactions.initiator;

import ballerina.util;
import ballerina.math;

public function main (string[] args) {
    println("Initiating transaction...");

    json txnContext = beginTransaction();

    boolean successful = callBusinessService(txnContext);
    if (successful) {
        _ = commitTransaction(txnContext);
    } else {
        _ = abortTransaction(txnContext);
    }
    //sleep(1000);
}

struct CreateTransactionContextRequest {
    string participantId;
    string coordinationType;
}

struct UpdateStockQuoteRequest {
    string symbol;
    float price;
}

struct CommitRequest {
    string transactionId;
}

struct CommitResponse {
    string message;
}

struct AbortRequest {
    string transactionId;
}

struct AbortResponse {
    string message;
}

function beginTransaction () returns (json) {
    endpoint<CoordinatorClient> coordinatorEP {
        create CoordinatorClient();
    }
    CreateTransactionContextRequest ctcReq = {participantId:util:uuid(), coordinationType:"2pc"};
    var j, e = coordinatorEP.createContext(ctcReq);
    println(e);
    println(j);
    return j;
}

function callBusinessService (json txnContext) returns (boolean successful) {
    endpoint<BizClient> participantEP {
        create BizClient();
    }
    var txnId, _ = (string)txnContext["transactionId"];
    var regURL, _ = (string)txnContext["registerAtURL"];

    float price = math:randomInRange(200, 250) + math:random();
    UpdateStockQuoteRequest bizReq = {symbol:"GOOG", price:price};
    var j, e = participantEP.updateStock(txnId, regURL, bizReq, "127.0.0.1", 8888);
    if (e != null) {
        successful = false;
        return;
    }
    j, e = participantEP.updateStock(txnId, regURL, bizReq, "127.0.0.1", 8889);
    if (e != null) {
        successful = false;
        return;
    }
    println(e);
    println(j);
    return true;
}

function commitTransaction (json txnContext) returns (json) {
    endpoint<CoordinatorClient> coordinatorEP {
        create CoordinatorClient();
    }
    println("Committing transaction...");
    var txnId, _ = (string)txnContext["transactionId"];
    CommitRequest commitReq = {transactionId:txnId};
    var j, e = coordinatorEP.commitTransaction(commitReq);
    println(e);
    println(j);
    return j;
}

function abortTransaction (json txnContext) returns (json) {
    endpoint<CoordinatorClient> coordinatorEP {
        create CoordinatorClient();
    }
    println("Aborting transaction...");
    var txnId, _ = (string)txnContext["transactionId"];
    AbortRequest abortReq = {transactionId:txnId};
    var j, e = coordinatorEP.abortTransaction(abortReq);
    println(e);
    println(j);
    return j;
}
