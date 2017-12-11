package ballerina.transactions.coordinator;
import ballerina.log;

public const string PROTOCOL_COMPLETION = "completion";
public const string PROTOCOL_VOLATILE = "volatile";
public const string PROTOCOL_DURABLE = "durable";

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
}

enum TransactionState {
    ACTIVE, PREPARED, COMMITTED, ABORTED
}

struct TwoPhaseCommitTransaction {
    string transactionId;
    string coordinationType = "2pc";
    map participants;
    TransactionState state;
    boolean possibleMixedOutcome;
}

struct CommitRequest {
    string transactionId;
}

struct CommitResponse {
    string message;
}

struct PrepareRequest {
    string transactionId;
}

struct PrepareResponse {
    string message;
}

struct NotifyRequest {
    string transactionId;
    string message;
}

struct NotifyResponse {
    string message;
}

struct AbortRequest {
    string transactionId;
}

struct AbortResponse {
    string message;
}

function twoPhaseCommit (TwoPhaseCommitTransaction txn) returns (string message) {
    log:printInfo("Running 2-phase commit for transaction: " + txn.transactionId);
    map participants = txn.participants;
    any[] p = participants.values();
    string[] volatileEndpoints = [];
    string[] durableEndpoints = [];
    int i = 0;
    while (i < lengthof p) {
        var participant, _ = (Participant)p[i];
        Protocol[] protocols = participant.participantProtocols;
        if (protocols != null) {
            int j = 0;
            while (j < lengthof protocols) {
                Protocol proto = protocols[j];
                if (proto.name == PROTOCOL_VOLATILE) {
                    volatileEndpoints[lengthof volatileEndpoints] = proto.url;
                } else if (proto.name == PROTOCOL_DURABLE) {
                    durableEndpoints[lengthof durableEndpoints] = proto.url;
                }
                j = j + 1;
            }
        }
        i = i + 1;
    }
    // Prepare phase & commit phase
    // First call prepare on all volatile participants
    boolean voteSuccess = prepare(txn, volatileEndpoints);
    if (voteSuccess) {
        // if all volatile participants voted YES, Next call prepare on all durable participants
        voteSuccess = prepare(txn, durableEndpoints);
        if (voteSuccess) {
            // If all durable participants voted YES (PREPARED or READONLY), next call notify(commit) on all
            // (durable & volatile) participants and return committed to the initiator
            string status = notify(txn, durableEndpoints, "commit"); //TODO: Properly handle status
            status = notify(txn, volatileEndpoints, "commit"); //TODO: Properly handle status
            message = "committed";
        } else {
            // If some durable participants voted NO, next call notify(abort) on all durable participants
            // and return aborted to the initiator
            string status = notify(txn, durableEndpoints, "abort"); //TODO: Properly handle status
            status = notify(txn, volatileEndpoints, "abort"); //TODO: Properly handle status
            if (txn.possibleMixedOutcome) {
                message = "mixed";
            } else {
                message = "aborted";
            }
        }
    } else {
        string status = notify(txn, volatileEndpoints, "abort"); //TODO: Properly handle status
        if (txn.possibleMixedOutcome) {
            message = "mixed";
        } else {
            message = "aborted";
        }
    }
    return;
}

function prepare (TwoPhaseCommitTransaction txn, string[] participantURLs) returns (boolean successful) {
    endpoint<ParticipantClient> participantEP {
    }
    string transactionId = txn.transactionId;
    successful = true;
    int i = 0;
    while (i < lengthof participantURLs) {
        ParticipantClient participantClient = create ParticipantClient();
        bind participantClient with participantEP;

        log:printInfo("Preparing participant: " + participantURLs[i]);
        // If a participant voted NO then abort
        var status, e = participantEP.prepare(transactionId, participantURLs[i]);
        if (e != null || status == "aborted") {
            log:printInfo("Participant: " + participantURLs[i] + " failed or aborted");
            successful = false;
            break;
        } else if (status == "committed") {
            log:printInfo("Participant: " + participantURLs[i] + " committed");
            // If one or more participants returns "committed" and the overall prepare fails, we have to
            // report a mixed-outcome to the initiator
            txn.possibleMixedOutcome = true;
            // Don't send notify to this participant because it is has already committed. We can forget about this participant.
            participantURLs[i] = null; //TODO: Nulling this out because there is no way to remove an element from an array
        } else if (status == "read-only") {
            log:printInfo("Participant: " + participantURLs[i] + " read-only");
            // Don't send notify to this participant because it is read-only. We can forget about this participant.
            participantURLs[i] = null; //TODO: Nulling this out because there is no way to remove an element from an array
        } else {
            log:printInfo("Participant: " + participantURLs[i] + ", status: " + status);
        }
        i = i + 1;
    }
    return;
}

function notifyAll (TwoPhaseCommitTransaction txn, string message) returns (string status) {
    map participants = txn.participants;
    string transactionId = txn.transactionId;
    any[] p = participants.values();
    int i = 0;
    while (i < lengthof p) {
        var participant, _ = (Participant)p[i];
        Protocol[] protocols = participant.participantProtocols;
        if (protocols != null) {
            int j = 0;
            while (j < lengthof protocols) {
                Protocol proto = protocols[j];
                status = notifyParticipant(transactionId, proto.url, message); //TODO: Properly handle status
                j = j + 1;
            }
        }
        i = i + 1;
    }
    return;
}

function notify (TwoPhaseCommitTransaction txn, string[] participantURLs, string message) returns (string status) {
    string transactionId = txn.transactionId;
    int i = 0;
    while (i < lengthof participantURLs) {
        string participantURL = participantURLs[i];
        if(participantURL != null) {
            status = notifyParticipant(transactionId, participantURL, message); //TODO: Properly handle status
        }
        i = i + 1;
    }
    return;
}

function notifyParticipant(string transactionId, string url, string message) returns (string){
    endpoint<ParticipantClient> participantEP {
    }
    ParticipantClient participantClient = create ParticipantClient();
    bind participantClient with participantEP;

    log:printInfo("Notify(" + message + ") participant: " + url);

    // TODO If a participant voted NO then abort
    var status, e = participantEP.notify(transactionId, url, message);
    print("++++ Error:"); println(e);
    println("+++++ status:" + status);

    // TODO: participant may return "Transaction-Unknown", "Not-Prepared" or "Failed-EOT"
    if (e != null || status == "aborted") {
        log:printInfo("Participant: " + url + " aborted");
        // TODO: handle this
    } else if (status == "committed") {
        log:printInfo("Participant: " + url + " committed");
    }
    return status;
}
