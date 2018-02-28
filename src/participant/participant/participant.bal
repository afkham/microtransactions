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

import ballerina.caching;
import ballerina.config;
import ballerina.log;
import ballerina.net.http;
import ballerina.util;
import ballerina.io;
import ballerina.transactions.coordinator;

@http:configuration {
    basePath:"/stockquote",
    host:participantHost,
    port:participantPort
}
service<http> stockquoteService {
    string participantId = util:uuid();

    caching:Cache stockCache = caching:createCache("stocks", 30000, 10, 0.25);
    map persistentStocks = {};

    @http:resourceConfig {
        path:"/update"
    }
    resource updateStockQuote (http:Connection conn, http:InRequest req) {
        http:OutResponse res;
        transaction {
            log:printInfo("Received update stockquote request");
            var updateReq, _ = <UpdateStockQuoteRequest>req.getJsonPayload();
            log:printInfo("Update stock quote request received. symbol:" + updateReq.symbol +
                          ", price:" + updateReq.price);
        }

        json jsonRes = {"message":"updating stock"};
        res = {statusCode:200};
        res.setJsonPayload(jsonRes);
        _ = conn.respond(res);
    }
}

struct UpdateStockQuoteRequest {
    string symbol;
    float price;
}

const string participantHost = getParticipantHost();
const int participantPort = getParticipantPort();

function getParticipantHost () returns (string host) {
    host = config:getInstanceValue("http", "participant.host");
    if (host == "") {
        host = "localhost";
    }
    return;
}

function getParticipantPort () returns (int port) {
    var p, e = <int>config:getInstanceValue("http", "participant.port");
    if (e != null) {
        port = 8081;
    } else {
        port = p;
    }
    return;
}
