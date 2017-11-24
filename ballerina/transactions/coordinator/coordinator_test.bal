package ballerina.transactions.coordinator;
import ballerina.test;

public function testProtocolCompatibility1 () {
    Protocol[] protos = [{name:"X"}, {name:"volatile"}, {name:"durable"}];
    boolean isCompatible = protocolCompatible(TWO_PHASE_COMMIT, protos);
    test:assertBooleanEquals(isCompatible, false, "Protocols should have been compatible");
}

public function testProtocolCompatibility2 () {
    Protocol[] protos = [{name:"volatile"}, {name:"x"}, {name:"durable"}];
    boolean isCompatible = protocolCompatible(TWO_PHASE_COMMIT, protos);
    test:assertBooleanEquals(isCompatible, false, "Protocols should have been incompatible");
}

public function testProtocolCompatibility3 () {
    Protocol[] protos = [{name:"volatile"}, {name:"durable"}, {name:"x"}];
    boolean isCompatible = protocolCompatible(TWO_PHASE_COMMIT, protos);
    test:assertBooleanEquals(isCompatible, false, "Protocols should have been incompatible");
}

public function testProtocolCompatibility4 () {
    Protocol[] protos = [{name:"volatile"}];
    boolean isCompatible = protocolCompatible(TWO_PHASE_COMMIT, protos);
    test:assertBooleanEquals(isCompatible, true, "Protocols should have been compatible");
}

public function testProtocolCompatibility5 () {
    Protocol[] protos = [{name:"volatile"}, {name:"completion"}, {name:"durable"}, {name:"foo"}];
    boolean isCompatible = protocolCompatible(TWO_PHASE_COMMIT, protos);
    test:assertBooleanEquals(isCompatible, false, "Protocols should have been incompatible");
}

public function testProtocolCompatibility6 () {
    Protocol[] protos = [{name:"volatile"}, {name:"completion"}, {name:"durable"}];
    boolean isCompatible = protocolCompatible(TWO_PHASE_COMMIT, protos);
    test:assertBooleanEquals(isCompatible, true, "Protocols should have been compatible");
}
