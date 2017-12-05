package ballerina.transactions.participant;

import ballerina.net.http;
import ballerina.util;

@http:configuration {
    basePath:"/",
    host:participantHost,
    port:participantPort
}
service<http> participantService {
    string participantId = util:uuid();

    resource updateStockQuote (http:Request req, http:Response res) {
        endpoint<TransactionClient> coordinatorEP {
            create TransactionClient();
        }
        println("Update stock quote request received");
        json payload = req.getJsonPayload();
        println(payload);

        var txnId, _ = (string) payload["transactionId"];
        var registerAtURL, _ = (string) payload["registerAtURL"];
        var j, e = coordinatorEP.register(txnId, participantId, registerAtURL);
        println(j);
        println(e);

        _ = res.send();
    }

    resource prepare (http:Request req, http:Response res) {
        println("prepare received");
    }

    resource notify (http:Request req, http:Response res) {
        println("notify received");
    }
}
