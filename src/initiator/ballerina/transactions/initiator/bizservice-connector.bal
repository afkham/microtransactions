package ballerina.transactions.initiator;
import ballerina.net.http;

public connector BizClient () {

    action call (string transactionId, string registerAtUrl, UpdateStockQuoteRequest bizReq,
                 string host, int port) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient("http://" + host + ":" + port + "/updateStockQuote", {});
        }
        var j, _ = <json>bizReq;
        http:Request req = {};
        req.setHeader("X-XID", transactionId);
        req.setHeader("X-Register-At-URL", registerAtUrl);
        req.setJsonPayload(j);
        var res, e = bizEP.post("", req);
        if (e == null) {
            http:Response r = (http:Response)res;
            jsonRes = r.getJsonPayload();
        } else {
            err = (error)e;
        }
        return;
    }
}

