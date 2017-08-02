@testable import Optics
import SwiftCheck

struct Pair<A: Arbitrary & Equatable, B: Arbitrary & Equatable>: Arbitrary, Equatable {
	var a: A
	var b: B

	public static var arbitrary: Gen<Pair<A, B>> {
		return Gen.compose { Pair.init(a: $0.generate(), b: $0.generate()) }
	}

	static func == (left: Pair, right: Pair) -> Bool {
		return left.a == right.a
			&& left.b == right.b
	}

	enum lens {
		static var a: Lens<Pair<A,B>,A> {
			return Lens<Pair<A,B>,A>.init(
				get: { whole in whole.a },
				set: { part in { whole in var m = whole; m.a = part; return m }})
		}

		static var b: Lens<Pair<A,B>,B> {
			return Lens<Pair<A,B>,B>.init(
				get: { whole in whole.b },
				set: { part in { whole in var m = whole; m.b = part; return m }})
		}
	}
}

struct OptionalPair<A: Arbitrary & Equatable, B: Arbitrary & Equatable>: Arbitrary, Equatable {
	var a: A?
	var b: B?

	public static var arbitrary: Gen<OptionalPair<A, B>> {
		return Gen.compose { OptionalPair.init(a: $0.generate(using: OptionalOf<A>.arbitrary.map { $0.getOptional }), b: $0.generate(using: OptionalOf<B>.arbitrary.map { $0.getOptional })) }
	}

	static func == (left: OptionalPair, right: OptionalPair) -> Bool {
		return left.a == right.a
			&& left.b == right.b
	}

	enum lens {
		static var a: Lens<OptionalPair<A,B>,A?> {
			return Lens<OptionalPair<A,B>,A?>.init(
				get: { whole in whole.a },
				set: { part in { whole in var m = whole; m.a = part; return m }})
		}

		static var b: Lens<OptionalPair<A,B>,B?> {
			return Lens<OptionalPair<A,B>,B?>.init(
				get: { whole in whole.b },
				set: { part in { whole in var m = whole; m.b = part; return m }})
		}
	}
}

enum Sum<A: Equatable,B: Equatable>: Equatable {

	case left(A)
	case right(B)

	static func == (left: Sum<A,B>, right: Sum<A,B>) -> Bool {
		switch (left,right) {
		case (.left(let leftValue),.left(let rightValue)):
			return leftValue == rightValue
		case (.right(let leftValue),.right(let rightValue)):
			return leftValue == rightValue
		default:
			return false
		}
	}

	static var leftPrism: Prism<Sum,A> {
		return Prism<Sum,A>(
			tryGet: { if case .left(let value) = $0 { return value } else { return nil } },
			inject: { .left($0) })
	}

	static var rightPrism: Prism<Sum,B> {
		return Prism<Sum,B>(
			tryGet: { if case .right(let value) = $0 { return value } else { return nil } },
			inject: { .right($0) })
	}
}

struct ArbitrarySum<A: Equatable & Arbitrary, B: Equatable & Arbitrary>: Arbitrary {

	let get: Sum<A,B>

	init(_ get: Sum<A,B>) {
		self.get = get
	}

	static var arbitrary: Gen<ArbitrarySum<A, B>> {
		return Gen<Int>.fromElements(of: [0,1])
			.flatMap {
				switch $0 {
				case 0:
					return A.arbitrary.map(Sum.left)
				case 1:
					return B.arbitrary.map(Sum.right)
				default:
					fatalError()
				}
			}
			.map(ArbitrarySum.init)
	}
}
