package ballerina.transactions.coordinator;

import ballerina.net.http;

public connector ParticipantClient () {

    action prepare (string transactionId, string participantURL) returns
                                                                 (string status, error err) {
        endpoint<http:HttpClient> participantEP {
            create http:HttpClient(participantURL, {});
        }
        http:Request req = {};
        PrepareRequest prepareReq = {transactionId:transactionId};
        var j, _ = <json>prepareReq;
        req.setJsonPayload(j);
        var res, e = participantEP.post("/prepare", req);
        if (e == null) {
            if (res.getStatusCode() == 200) {
                var prepareRes, e2 = <PrepareResponse>res.getJsonPayload();
                if (e2 == null) {
                    status = prepareRes.message;
                } else {
                    err = (error)e2;
                }
            } else if (res.getStatusCode() == 404) { // micro-transaction unknown
                var prepareRes, e2 = <PrepareResponse>res.getJsonPayload();
                if (e2 == null) {
                    err = {msg: prepareRes.message};
                } else {
                    err = (error)e2;
                }
            } else {
                err = {msg:"Prepare failed. Transaction: " + transactionId + ", Participant: " + participantURL};
            }
        } else {
            err = (error)e;
        }
        return;
    }

    action notify (string transactionId, string participantURL, string message) returns
                                                                                (string status, error err) {
        endpoint<http:HttpClient> participantEP {
            create http:HttpClient(participantURL, {});
        }
        http:Request req = {};
        NotifyRequest notifyReq = {transactionId:transactionId, message:message};
        var j, _ = <json>notifyReq;
        req.setJsonPayload(j);
        var res, e = participantEP.post("/notify", req);
        if (e == null) {
            if (res.getStatusCode() == 200) {
                var notifyRes, e2 = <NotifyResponse>res.getJsonPayload();
                if (e2 == null) {
                    status = notifyRes.message;
                    println("+++++++ Notify respose status:" + status);
                } else {
                    err = (error)e2;
                }
            } else if (res.getStatusCode() == 404 || res.getStatusCode() == 400) { // micro-transaction unknown or not-prepared
                var notifyRes, e2 = <NotifyResponse>res.getJsonPayload();
                if (e2 == null) {
                    err = {msg:notifyRes.message};
                } else {
                    err = (error)e2;
                }
            } else {
                err = {msg:"Notify failed. Transaction: " + transactionId + ", Participant: " + participantURL};
            }
        } else {
            err = (error)e;
        }
        return;
    }
}
