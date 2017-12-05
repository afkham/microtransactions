package ballerina.transactions.coordinator;

import ballerina.net.http;

public const string TWO_PHASE_COMMIT = "2pc";
public const string PROTOCOL_COMPLETION = "completion";
public const string PROTOCOL_VOLATILE = "volatile";
public const string PROTOCOL_DURABLE = "durable";

enum Protocols {
    COMPLETION, DURABLE, VOLATILE
}

function twoPhaseCommit (map participants) returns (boolean successful) {

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
    // First get all the volatile participants and call prepare on them
    boolean voteSuccess = prepare(volatileEndpoints);
    if(voteSuccess) {
        voteSuccess = prepare(durableEndpoints);
        if(voteSuccess) {

        } else {

        }
    } else {

    }

    return false;


    // If all volatile participants voted YES, get all the durable participants and call prepare on them
    // If all durable participants voted YES (PREPARED or READONLY), next call notify(commit) on all
    // (durable & volatile) participants
    // and return committed to the initiator
    // If some durable participants voted NO, next call notify(abort) on all durable participants
    // and return aborted to the initiator
}

function prepare(string[] participantURLs) returns(boolean voteSuccess) {
    endpoint<http:HttpClient> participantEP {
    }
    int i = 0;
    while(i < lengthof participantURLs) {
        http:HttpClient participantClient = create http:HttpClient(participantURLs[i], {});
        bind participantClient with participantEP;
        http:Request req = {};
        var res, e = participantEP.post("", req);

        // TODO If a participant voted NO then abort

        i = i + 1;
    }
    return false;
}

function notify(string message) {

}
