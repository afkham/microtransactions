package ballerina.transactions.coordinator;

import ballerina.net.http;

@http:configuration {
    basePath:"/2pc",
    host:coordinatorHost,
    port:coordinatorPort
}
service<http> twoPcCoordinator {

    @http:resourceConfig {
        path:"/commit"
    }
    resource commitTransaction (http:Request req, http:Response res) {
        //The following command is used to end a micro-transaction successfully,
        // i.e. committing all modifications of all participants. As a result, the coordinator
        // will initiate a prepare() (see section 2.2.5) for each participant.
        //
        //                                                         commit(in: Micro-Transaction-Identifier,
        //                                                         out: ( Committed | Aborted | Mixed )?,
        //                                                         fault: ( Micro-Transaction-Unknown |
        //                                                         Hazard-Outcome ? )
        //
        // The input parameter Micro-Transaction-Identifier is the globally unique identifier of the
        // micro-transaction the participant requests to commit. If the joint outcome is “commit” the output will be
        // Committed. If the joint outcome is “abort”, the output will be Aborted. In case at least one participant
        // performed its commit processing before it had been asked to vote on the joint outcome (e.g. because it was
        // blocking too long) but another participant voted “abort”, no joint outcome can be achieved and Mixed will be
        // the output.

        // If the Micro-Transaction-Identifier is not known to the coordinator, the following fault will be returned.
        // Micro-Transaction-Unknown

        // If at least one of the participants could not end its branch of the micro-transaction as requested
        // (see section 2.2.6), the following fault will be returned:

        // Hazard-Outcome

        // TODO: impl.
        // Get the transaction ID from the request
        var commitReq, e = <CommitRequest>req.getJsonPayload();
        if (e != null) {
            res.setStatusCode(400);
            RequestError err = {errorMessage:"Bad Request"};
            var resPayload, _ = <json>err;
            res.setJsonPayload(resPayload);
        } else {
            string txnId = commitReq.transactionId;
            var txn, _ = (Transaction)transactions[txnId];
            if (txn == null) {
                respondToBadRequest(res, "Transaction-Unknown. Invalid TID:" + txnId);
            } else {
                map participants = txn.participants;
                // TODO: return response to the initiator. ( Committed | Aborted | Mixed )
                string msg = twoPhaseCommit(txnId, participants);
                CommitResponse commitRes = {message:msg};
                var resPayload, _ = <json>commitRes;
                res.setJsonPayload(resPayload);
            }
        }

        // Prepare phase & commit phase
        // First get all the volatile participants and call prepare on them
        // If all volatile participants voted YES, get all the durable participants and call prepare on them
        // If all durable participants voted YES (PREPARED or READONLY), next call notify(commit) on all
        // (durable & volatile) participants
        // and return committed to the initiator
        // If some durable participants voted NO, next call notify(abort) on all durable participants
        // and return aborted to the initiator


        _ = res.send();
    }

    @http:resourceConfig {
        path:"/abort"
    }
    resource abortTransaction (http:Request req, http:Response res) {

    }

    @http:resourceConfig {
        path:"/replay"
    }
    resource replay (http:Request req, http:Response res) {

    }
}
