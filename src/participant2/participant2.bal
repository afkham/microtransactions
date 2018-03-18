// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina.data.sql;
import ballerina.io;
import ballerina.net.http;

endpoint http:ServiceEndpoint participantEP {
    host:"localhost",
    port:8890
};

@http:serviceConfig {
    basePath:"/p2",
}
service<http:Service> Participant2 bind participantEP {
    sql:ClientConnector sqlConn = create sql:ClientConnector(
                                  sql:DB.MYSQL, "localhost", 3306, "testdb", "root", "root", {maximumPoolSize:5});

    @http:resourceConfig {
        path:"/update/{symbol}/{price}"
    }
    update (endpoint conn, http:InRequest req, string symbol, string price) {
        endpoint<sql:ClientConnector> testDB {
            sqlConn;
        }

        var intPrice, _ = <int>price;

        boolean transactionSuccess = false;
        transaction with retries(4) {
            int updatedRows = testDB ->
                                    update("CREATE TABLE IF NOT EXISTS STOCK (SYMBOL VARCHAR(30), PRICE FLOAT)", null);
            int c = testDB.update("INSERT INTO STOCK(SYMBOL,PRICE) VALUES ('" + symbol + "', " + price + ")", null);
            io:println("Inserted count:" + c);

            if (c == 0) {
                abort;
            }
            transactionSuccess = true;
        } failed {
            io:println("Transaction failed");
            transactionSuccess = false;
        }
        if (transactionSuccess) {
            io:println("Transaction committed");
        }

        http:OutResponse res = {statusCode:200};
        _ = conn -> respond(res);
    }
}
