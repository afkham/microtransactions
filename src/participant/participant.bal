import ballerina.log;
import ballerina.io;
import ballerina.net.http;

@http:configuration {
    basePath:"/stockquote",
    host:"localhost",
    port:8889
}
service<http> stockquoteService {

    @http:resourceConfig {
        path:"/update"
    }
    resource updateStockQuote (http:Connection conn, http:InRequest req) {
        log:printInfo("Received update stockquote request");
        http:OutResponse res;
        transaction {
            io:println("1st transaction block");
        }
        transaction {
            io:println("2nd transaction block");
            json updateReq = req.getJsonPayload();
            string msg = io:sprintf("Update stock quote request received. symbol:%j, price:%j",
                                    [updateReq.symbol, updateReq.price]);
            log:printInfo(msg);

            json jsonRes = {"message":"updating stock"};
            res = {statusCode:200};
            res.setJsonPayload(jsonRes);
            var err = conn.respond(res);
            if (err != null) {
                log:printErrorCause("Could not send response back to initiator", err);
            } else {
                log:printInfo("Sent response back to initiator");
            }
        }
    }
}
