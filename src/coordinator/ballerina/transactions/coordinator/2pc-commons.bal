package ballerina.transactions.coordinator;

public const string PROTOCOL_COMPLETION = "completion";
public const string PROTOCOL_VOLATILE = "volatile";
public const string PROTOCOL_DURABLE = "durable";

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
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

function twoPhaseCommit (string transactionId, map participants) returns (string message) {
    var p, _ = (Participant[])participants.values();
    string[] volatileEndpoints = [];
    string[] durableEndpoints = [];
    int i = 0;
    while (i < lengthof p) {
        Participant participant = p[i];
        Protocol[] protocols = participant.participantProtocols;
        int j = 0;
        while(j < lengthof protocols) {
            Protocol proto = protocols[j];
            if(proto.name == PROTOCOL_VOLATILE) {
                volatileEndpoints[lengthof volatileEndpoints - 1] = proto.url;
            } else if (proto.name == PROTOCOL_DURABLE) {
                durableEndpoints[lengthof durableEndpoints - 1] = proto.url;
            }
            j = j + 1;
        }
        i = i + 1;
    }
    // Prepare phase & commit phase
    // First call prepare on all volatile participants
    boolean voteSuccess = prepare(transactionId, volatileEndpoints);
    if(voteSuccess) {
        // Next call prepare on all durable participants
        voteSuccess = prepare(transactionId, durableEndpoints);
        if(voteSuccess) {
            notify(transactionId, durableEndpoints, "commit");
            notify(transactionId, volatileEndpoints, "commit");
            message = "committed";
        } else {
            notify(transactionId, durableEndpoints, "abort");
            notify(transactionId, volatileEndpoints, "abort");
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

function prepare(string transactionId, string[] participantURLs) returns(boolean successful) {
    endpoint<ParticipantClient> participantEP {
    }
    successful = true;
    int i = 0;
    while(i < lengthof participantURLs) {
        ParticipantClient participantClient = create ParticipantClient();
        bind participantClient with participantEP;

        // TODO If a participant voted NO then abort
        var status, e = participantEP.prepare(transactionId, participantURLs[i]);
        if(e != null || status == "aborted") {
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

function notify(string transactionId, string[] participantURLs, string message) {
    endpoint<ParticipantClient> participantEP {
    }
    int i = 0;
    while(i < lengthof participantURLs) {
        ParticipantClient participantClient = create ParticipantClient();
        bind participantClient with participantEP;

        // TODO If a participant voted NO then abort
        var status, e = participantEP.notify(transactionId, participantURLs[i], message);
        if(e != null || status == "aborted") {
            // TODO: handle this
        } else if (status == "committed") {
            // TODO: handle mixed outcome if overall commit fails
        }
        i = i + 1;
    }
}
