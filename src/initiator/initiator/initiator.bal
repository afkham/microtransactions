// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package initiator;

import ballerina.math;
import ballerina.net.http;
import ballerina.log;
import ballerina.transactions.coordinator;

@http:configuration {
    basePath:"/",
    host:"localhost",
    port:8080
}
service<http> InitiatorService {

    @http:resourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource init (http:Connection conn, http:InRequest req) {
        log:printInfo("Initiating transaction...");
        transaction {
            boolean successful = callBusinessService();
        }

        http:OutResponse res = {statusCode:200};
        _ = conn.respond(res);
    }
}

struct UpdateStockQuoteRequest {
    string symbol;
    float price;
}

function callBusinessService () returns (boolean successful) {
    endpoint<BizClient> participantEP {
        create BizClient();
    }

    float price = math:randomInRange(200, 250) + math:random();
    UpdateStockQuoteRequest bizReq = {symbol:"GOOG", price:price};
    var j, e = participantEP.updateStock(bizReq, "127.0.0.1", 8889);
    if (e != null) {
        successful = false;
    }
    //j, e = participantEP.updateStock(txnId, regURL, bizReq, "127.0.0.1", 8889);
    //if (e != null) {
    //    successful = false;
    //    return;
    //}
    //log:printErrorCause("", e);
    //log:printInfo(j);
    return;
}

public connector BizClient () {

    action updateStock (UpdateStockQuoteRequest bizReq,
                        string host, int port) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient("http://" + host + ":" + port + "/stockquote/update", {});
        }
        var j, _ = <json>bizReq;
        http:OutRequest req = {};
        req.setJsonPayload(j);
        var res, e = bizEP.post("", req);
        log:printInfo("Got response from bizservice");
        if (e == null) {
            if (res.statusCode != 200) {
                err = {message:"Error occurred"};
            } else {
                jsonRes = res.getJsonPayload();
            }
        } else {
            err = (error)e;
        }
        return;
    }
}
