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

import ballerina.net.http;
import ballerina.data.sql;
import ballerina.io;

@http:configuration {
    basePath:"/p2",
    host:"localhost",
    port:8890
}
service<http> Participant2 {

    @http:resourceConfig {
        path:"/update/{symbol}/{price}"
    }
    resource update (http:Connection conn, http:InRequest req, string symbol, string price) {
        endpoint<sql:ClientConnector> testDB {
            create sql:ClientConnector(
            sql:DB.MYSQL, "localhost", 3306, "testdb", "root", "root", {maximumPoolSize:5});
        }

        var intPrice, _ = <int> price;
        int updatedRows =
        testDB.update("CREATE TABLE IF NOT EXISTS STOCK (SYMBOL VARCHAR(30), PRICE FLOAT)", null);

        boolean transactionSuccess = false;
        transaction with retries(4) {
            int c = testDB.update("INSERT INTO STOCK(SYMBOL,PRICE) VALUES ('" + symbol + "', "+ price + ")", null);
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

        testDB.close();
        http:OutResponse res = {statusCode:200};
        _ = conn.respond(res);
    }
}
