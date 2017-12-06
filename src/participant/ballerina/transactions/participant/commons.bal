package ballerina.transactions.participant;

public struct Protocol {
    string name;
    string url;
}

struct UpdateStockQuoteRequest {
    string transactionId;
    string registerAtURL;
    string symbol;
    float price;
}

struct RegistrationRequest {
    string transactionId;
    string participantId;
    Protocol[] participantProtocols;
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
