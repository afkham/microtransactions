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

import ballerina/mysql;
import ballerina/sql;
import ballerina/io;
import ballerina/log;
import ballerina/http;
//import ballerinax/kebernetes;

//@kubernetes:Service {
//    name: "participant2"
//}
endpoint http:Listener participantEP {
    host:"localhost",
    port:8890
};

endpoint mysql:Client testDB {
    host:"localhost",
    port:3306,
    name:"testdb",
    username:"root",
    password:"root",
    poolOptions:{maximumPoolSize:5}
};

@http:ServiceConfig {
    basePath:"/p2"
}
service Participant2 bind participantEP {

    @http:ResourceConfig {
        path:"/update/{symbol}/{price}"
    }
    update (endpoint conn,http:Request req, string symbol, float price) {
        io:println("##########################");

        transaction with retries = 4, oncommit = onCommitFn, onabort = onAbortFn {
            var result = testDB -> update("CREATE TABLE IF NOT EXISTS STOCK (SYMBOL VARCHAR(30), PRICE FLOAT)");
            int updatedRows = check result;

            io:println("##########################");

            var result2 = testDB -> update("INSERT INTO STOCK(SYMBOL,PRICE) VALUES (?,?)", symbol, price);
            updatedRows = check result2;

            io:println("Inserted count:" + updatedRows);

            if (updatedRows == 0) {
                abort;
            }
        } onretry {
            io:println("Retrying transaction...");
        }
        transaction {
            io:println("++++++ 2nd txn");
        }

        http:Response res = new; res.statusCode = 200;
        var result = conn -> respond(res);
        match result {
            error err => log:printError("Could not send response back to participant1", err = err);
            () => log:printInfo("");
        }
    }
}

function onCommitFn(string transactionId) {
    io:println("##### Committed: " + transactionId);
}

function onAbortFn(string transactionId) {
    io:println("##### Aborted: " + transactionId);
}
