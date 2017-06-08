precedencegroup CompositionLeftPrecedence {
	associativity: left
	higherThan: TernaryPrecedence
	lowerThan: LogicalDisjunctionPrecedence
}

infix operator >>> : CompositionLeftPrecedence
