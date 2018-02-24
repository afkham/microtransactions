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

package participant;
import ballerina.net.http;

public connector BizClient () {

    action updateStock (string transactionId, string registerAtUrl, UpdateStockQuoteRequest bizReq,
                 string host, int port) returns (json jsonRes, error err) {
        endpoint<http:HttpClient> bizEP {
            create http:HttpClient("http://" + host + ":" + port + "/updateStockQuote", {});
        }
        var j, _ = <json>bizReq;
        http:OutRequest req = {};
        req.setHeader("X-XID", transactionId);
        req.setHeader("X-Register-At-URL", registerAtUrl);
        req.setJsonPayload(j);
        var res, e = bizEP.post("", req);
        if (e == null) {
            http:InResponse r = (http:InResponse)res;
            jsonRes = r.getJsonPayload();
        } else {
            err = (error)e;
        }
        return;
    }
}

