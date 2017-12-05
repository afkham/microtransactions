package ballerina.transactions.initiator;
import ballerina.net.http;

public connector BizClient () {

    action call(BizRequest bizReq) returns (json jsonRes, error err){
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient("http://localhost:8081/updateStockQuote", {});
        }
        var j, _  = <json> bizReq;
        http:Request req = {};
        req.setJsonPayload(j);
        var res, e = bizEP.post("", req);
        if(e == null) {
            http:Response r = (http:Response) res;
            jsonRes = r.getJsonPayload();
        } else {
            err = (error) e;
        }
        return;
    }
}

