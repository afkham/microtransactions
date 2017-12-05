package ballerina.transactions.initiator;

import ballerina.net.http;

public connector TransactionClient () {

    action createContext(CreateTransactionContextRequest ctcReq) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> coordinatorEP {
            create http:HttpClient("http://localhost:8080/txnmgr/createContext", {});
        }
        var j, _  = <json> ctcReq;
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

    action commitTransaction(){

    }

    action abortTransaction(){

    }
}
