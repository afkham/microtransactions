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

        var txnId, _ = (string)payload["transactionId"];
        var registerAtURL, _ = (string)payload["registerAtURL"];
        var j, e = coordinatorEP.register(txnId, participantId, registerAtURL);
        println(j);
        println(e);
        json j2 = {"message":"updating stock"};
        res.setJsonPayload(j2);
        _ = res.send();
    }

    resource prepare (http:Request req, http:Response res) {
        println("prepare received");
        println(req.getJsonPayload());

        var prepareReq, _ = <PrepareRequest>req.getJsonPayload();
        println(prepareReq.transactionId);

        PrepareResponse prepareRes = {message:"readonly"};

        var j, _ = <json>prepareRes;
        res.setJsonPayload(j);
        _ = res.send();
    }

    resource notify (http:Request req, http:Response res) {
        println("notify received");
        println(req.getJsonPayload());
        var notReq, _ = <NotifyRequest>req.getJsonPayload();
        println(notReq.transactionId);
        println(notReq.message);

        NotifyResponse notRes = {message:"committed"};

        var j, _ = <json> notRes;
        res.setJsonPayload(j);
        _ = res.send();
    }

    resource abortTransaction (http:Request req, http:Response res) {

        _ = res.send();
    }
}
