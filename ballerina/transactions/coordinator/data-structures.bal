package ballerina.transactions.coordinator;

const string TRANSACTION_CONTEXT_VERSION = "1.0";

enum TransactionState {
    PREPARED, COMMITTED, ABORTED
}

struct Transaction {
    string coordinationType = "2pc";
    TransactionState state;
    map participants;
}

struct Participant {
    string participantId;
    Protocol[] participantProtocols;
    boolean isInitiator;
}

struct CreateTransactionContextRequest {
    string participantId;
    string coordinationType;
    Protocol[] participantProtocols;
}

struct TransactionContext {
    string contextVersion = "1.0";
    string transactionId;
    string coordinationType;
    string registerAtURL;
}

struct Protocol {
    string name;
    string url;
}

struct RegistrationRequest {
    string transactionId;
    string participantId;
    Protocol[] participantProtocols;
}

struct RegistrationResponse {
    string transactionId;
    Protocol[] coordinatorProtocols;
}

struct RequestError {
    string errorMessage;
}
