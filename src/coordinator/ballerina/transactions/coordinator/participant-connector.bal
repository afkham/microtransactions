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
        var res, e = participantEP.post("", req);
        if (e == null) {
            res = (http:Response)res;
            var prepRes, e2 = <PrepareResponse>res.getJsonPayload();
            if (e2 == null) {
                PrepareResponse prepareRes = (PrepareResponse)prepRes;
                status = prepareRes.message;
            } else {
                err = (error)e2;
            }
        } else {
            err = (error)e;
        }
        //TODO: handle micro-transaction unknown
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
        var res, e = participantEP.post("", req);
        if (e == null) {
            res = (http:Response)res;
            var notRes, e2 = <NotifyResponse>res.getJsonPayload();
            if (e2 == null) {
                NotifyResponse notifyRes = (NotifyResponse)notRes;
                status = notifyRes.message;
            } else {
                err = (error)e2;
            }
        } else {
            err = (error)e;
        }
        //TODO impl
    }
}
