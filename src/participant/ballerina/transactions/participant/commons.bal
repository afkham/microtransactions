package ballerina.transactions.participant;

public struct Protocol {
    string name;
    string url;
}

struct RegistrationRequest {
    string transactionId;
    string participantId;
    Protocol[] participantProtocols;
}
