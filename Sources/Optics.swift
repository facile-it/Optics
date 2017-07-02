/// A "OpticsType" is a type with references to a "Whole" and a "Part"

public protocol OpticsType {
	associatedtype WholeType
	associatedtype PartType
}

precedencegroup OpticsCompositionPrecedence {
	associativity: left
	higherThan: BitwiseShiftPrecedence
}

infix operator .. : OpticsCompositionPrecedence
