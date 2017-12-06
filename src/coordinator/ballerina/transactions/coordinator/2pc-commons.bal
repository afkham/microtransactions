package ballerina.transactions.coordinator;

public const string PROTOCOL_COMPLETION = "completion";
public const string PROTOCOL_VOLATILE = "volatile";
public const string PROTOCOL_DURABLE = "durable";

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
}

enum TransactionState {
    PREPARED, COMMITTED, ABORTED
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

function twoPhaseCommit (TwoPhaseCommitTransaction txn, map participants) returns (string message) {
    println("********* running 2pc coordination");
    println(participants.values());
    any[] p = participants.values();
    //println(typeof participants.values());
    //println(e);
    string[] volatileEndpoints = [];
    string[] durableEndpoints = [];
    int i = 0;
    while (i < lengthof p) {
        var participant, _ = (Participant)p[i];
        println(participant);
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
        // Next call prepare on all durable participants
        voteSuccess = prepare(txn, durableEndpoints);
        if (voteSuccess) {
            notify(txn, durableEndpoints, "commit");
            notify(txn, volatileEndpoints, "commit");
            message = "committed";
        } else {
            notify(txn, durableEndpoints, "abort");
            notify(txn, volatileEndpoints, "abort");
            message = "aborted";
        }
    } else {
        message = "aborted";
    }
    // TODO: message = "mixed" case should be handled
    return;


    // If all volatile participants voted YES, get all the durable participants and call prepare on them
    // If all durable participants voted YES (PREPARED or READONLY), next call notify(commit) on all
    // (durable & volatile) participants
    // and return committed to the initiator
    // If some durable participants voted NO, next call notify(abort) on all durable participants
    // and return aborted to the initiator
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

        // If a participant voted NO then abort
        var status, e = participantEP.prepare(transactionId, participantURLs[i]);
        if (e != null || status == "aborted") {
            successful = false;
            break;
        } else if (status == "committed") {
            // TODO: handle mixed outcome if overall commit fails. Mark the transaction as possible mixed outcome.
            // TODO: Next if the notify fails, then return "mixed" outcome
        }
        i = i + 1;
    }
    return;
}

function notify (TwoPhaseCommitTransaction txn, string[] participantURLs, string message) {
    endpoint<ParticipantClient> participantEP {
    }
    string transactionId = txn.transactionId;
    int i = 0;
    while (i < lengthof participantURLs) {
        ParticipantClient participantClient = create ParticipantClient();
        bind participantClient with participantEP;

        // TODO If a participant voted NO then abort
        var status, e = participantEP.notify(transactionId, participantURLs[i], message);
        print("++++ Error"); println(e);
        println("+++++ status:" + status);
        if (e != null || status == "aborted") {
            // TODO: handle this
        } else if (status == "committed") {
            // TODO: handle mixed outcome if overall commit fails
        }
        i = i + 1;
    }
}
