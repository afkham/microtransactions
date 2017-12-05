package ballerina.transactions.initiator;

import ballerina.util;

public function main (string[] args) {
    println("Initiating transaction...");

    json txnContext = beginTransaction();

    callBusinessService(txnContext);
    commitTransaction();
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

function beginTransaction () returns (json) {
    endpoint<TransactionClient> participantEP {
        create TransactionClient();
    }
    CreateTransactionContextRequest ctcReq = {participantId:util:uuid(), coordinationType:"2pc"};
    var j, e = participantEP.createContext(ctcReq);
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

function commitTransaction () {

}

function abortTransaction () {

}
