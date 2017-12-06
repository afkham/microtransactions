package ballerina.transactions.participant;

import ballerina.net.http;

public connector TransactionClient () {

    action register(string transactionId, string participantId, string registerAtURL) returns
                                                                                      (json jsonRes, error err){
        endpoint<http:HttpClient> coordinatorEP {
            create http:HttpClient(registerAtURL, {});
        }
        RegistrationRequest regReq = {transactionId:transactionId, participantId:participantId};
        Protocol[] protocols = [{name:"volatile", url:"http://localhost:8081/"}];
        regReq.participantProtocols = protocols;

        var j, _  = <json> regReq;
        http:Request req = {};
        req.setJsonPayload(j);
        var res, e = coordinatorEP.post("", req);
        if(e == null) {
            http:Response r = (http:Response) res;
            jsonRes = r.getJsonPayload();
        } else {
            err = (error) e;
        }
        return;
    }
}
