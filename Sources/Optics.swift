/// A "OpticsType" is a type with references to a "Whole" and a "Part"

public protocol OpticsType {
    associatedtype SType
    associatedtype TType
    associatedtype AType
    associatedtype BType
}

precedencegroup OpticsCompositionPrecedence {
	associativity: left
	higherThan: BitwiseShiftPrecedence
}

infix operator .. : OpticsCompositionPrecedence
