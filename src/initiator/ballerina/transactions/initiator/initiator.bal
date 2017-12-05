package ballerina.transactions.initiator;

import ballerina.util;

public function main (string[] args) {
    println("Initiating transaction...");

    json txnContext = beginTransaction();

    callBusinessService(txnContext);
    _ = commitTransaction(txnContext);
    sleep(1000);
}

struct CreateTransactionContextRequest {
    string participantId;
    string coordinationType;
}

struct BizRequest {
    string transactionId;
    string registerAtURL;
    string stockItem;
    float price;
}

struct CommitRequest {
    string transactionId;
}

struct CommitResponse {
    string message;
}

function beginTransaction () returns (json) {
    endpoint<TransactionClient> coordinatorEP {
        create TransactionClient();
    }
    CreateTransactionContextRequest ctcReq = {participantId:util:uuid(), coordinationType:"2pc"};
    var j, e = coordinatorEP.createContext(ctcReq);
    println(e);
    println(j);
    return j;
}

function callBusinessService (json txnContext) {
    endpoint<BizClient> participantEP {
        create BizClient();
    }
    var tid, _ = (string )txnContext["transactionId"];
    var regURL, _ = (string )txnContext["registerAtURL"];
    BizRequest bizReq = {transactionId:tid,
                            registerAtURL:regURL, stockItem:"GOOG", price:200.67};
    var j, e = participantEP.call(bizReq);
    println(e);
    println(j);
}

function commitTransaction (json txnContext) returns (json) {
    endpoint<TransactionClient> coordinatorEP {
        create TransactionClient();
    }
    var txnId, _ = (string) txnContext["transactionId"];
    CommitRequest commitReq = {transactionId:txnId};
    var j, e = coordinatorEP.commitTransaction(commitReq);
    println(e);
    println(j);
    return j;
}

function abortTransaction () {

}
