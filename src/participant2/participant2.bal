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

import ballerina/data.sql;
import ballerina/io;
import ballerina/log;
import ballerina/net.http;

endpoint http:ServiceEndpoint participantEP {
    host:"localhost",
    port:8890
};

endpoint sql:Client testDB {
    database:sql:DB.MYSQL,
    host:"localhost",
    port:3306,
    name:"testdb?useSSL=false",
    username:"root",
    password:"root",
    options:{maximumPoolSize:5}
};

@http:ServiceConfig {
    basePath:"/p2"
}
service<http:Service> Participant2 bind participantEP {

    @http:ResourceConfig {
        path:"/update/{symbol}/{price}"
    }
    update (endpoint conn,http:Request req, string symbol, float price) {

        boolean transactionSuccess = false;
        transaction with retries = 4, oncommit = onCommitFn, onabort = onAbortFn {
            int updatedRows =? testDB -> update("CREATE TABLE IF NOT EXISTS STOCK (SYMBOL VARCHAR(30), PRICE FLOAT)",
                                                null);

            sql:Parameter[] params = [];
            sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:symbol};
            sql:Parameter para2 = {sqlType:sql:Type.FLOAT, value:price};
            params = [para1, para2];
            updatedRows =? testDB -> update("INSERT INTO STOCK(SYMBOL,PRICE) VALUES (?,?)", params);
            io:println("Inserted count:" + updatedRows);

            if (updatedRows == 0) {
                abort;
            }
            transactionSuccess = true;
        } onretry {
            io:println("Transaction failed");
            transactionSuccess = false;
        }
        if (transactionSuccess) {
            io:println("Transaction committed");
        }

        http:Response res = {statusCode:200};
        var result = conn -> respond(res);
        match result {
            http:HttpConnectorError err => log:printErrorCause("Could not send response back to participant1", err);
            null => return;
        }
    }
}

function onCommitFn() {
    io:println("##### Committed");
}

function onAbortFn() {
    io:println("##### Aborted");
}
