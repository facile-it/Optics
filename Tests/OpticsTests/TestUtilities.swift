@testable import Optics
import SwiftCheck

struct Product<A: Equatable,B: Equatable>: Equatable {
	let left: A
	let right: B
	init(left: A, right: B) {
		self.left = left
		self.right = right
	}

	var decompose: (A,B) {
		return (left,right)
	}

	static func == (left: Product<A,B>, right: Product<A,B>) -> Bool {
		return left.left == right.left
			&& left.right == right.right
	}

	static var leftLens: Lens<Product,A> {
		return Lens(
			get: { $0.left },
			set: { part in { whole in Product(left: part, right: whole.right) } })
	}

	static var rightLens: Lens<Product,B> {
		return Lens(
			get: { $0.right },
			set: { part in { whole in Product(left: whole.left, right: part) } })
	}
}

struct ArbitraryProduct<A: Equatable & Arbitrary, B: Equatable & Arbitrary>: Arbitrary {

	let get: Product<A,B>

	init(_ get: Product<A,B>) {
		self.get = get
	}

	static var arbitrary: Gen<ArbitraryProduct<A,B>> {
		return Gen<(A,B)>
			.zip(A.arbitrary, B.arbitrary)
			.map(Product.init)
			.map(ArbitraryProduct.init)
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
