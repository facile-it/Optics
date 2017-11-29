import FunctionalKit

/// A "OpticsType" is a type with references to a "Whole" and a "Part"

public protocol OpticsType {
    associatedtype SType
    associatedtype TType
    associatedtype AType
    associatedtype BType
}

extension Product {
	public enum lens {
		public static func first<T>(to: T.Type) -> LensFull<Product<A,B>,Product<T,B>,A,T> {
			return LensFull<Product<A,B>,Product<T,B>,A,T>.init(
				get: { product in product.first },
				set: { t in { product in product.mapFirst(fconstant(t)) } })
		}

		public static func second<T>(to: T.Type) -> LensFull<Product<A,B>,Product<A,T>,B,T> {
			return LensFull<Product<A,B>,Product<A,T>,B,T>.init(
				get: { product in product.second },
				set: { t in { product in product.mapSecond(fconstant(t)) } })
		}

		public static var firstSame: Lens<Product<A,B>,A> {
			return first(to: A.self)
		}

		public static var secondSame: Lens<Product<A,B>,B> {
			return second(to: B.self)
		}
	}
}

extension Coproduct {
	public enum prism {
		public static func left<T>(to: T.Type) -> PrismFull<Coproduct<A,B>,Coproduct<T,B>,A,T> {
			return PrismFull<Coproduct<A,B>,Coproduct<T,B>,A,T>.init(
				tryGet: { coproduct in  coproduct.tryLeft },
				inject: { t in .left(t) })
		}

		public static func right<T>(to: T.Type) -> PrismFull<Coproduct<A,B>,Coproduct<A,T>,B,T> {
			return PrismFull<Coproduct<A,B>,Coproduct<A,T>,B,T>.init(
				tryGet: { coproduct in  coproduct.tryRight },
				inject: { t in .right(t) })
		}

		public static var leftSame: Prism<Coproduct<A,B>,A> {
			return left(to: A.self)
		}

		public static var rightSame: Prism<Coproduct<A,B>,B> {
			return right(to: B.self)
		}
	}
}

extension Inclusive {
	public enum affine {
		public static func left<T>(to: T.Type) -> AffineFull<Inclusive<A,B>,Inclusive<T,B>,A,T> {
			return AffineFull<Inclusive<A,B>,Inclusive<T,B>,A,T>.init(
				tryGet: { inclusive in inclusive.tryLeft },
				trySet: { t in
					{ inclusive in
						inclusive.fold(
							onLeft: fconstant(.left(t)),
							onCenter: { _, b in .center(t,b) },
							onRight: fconstant(nil))
					}
			})
		}

		public static func center<T,U>(to: (T.Type,U.Type)) -> AffineFull<Inclusive<A,B>,Inclusive<T,U>,(A,B),(T,U)> {
			return AffineFull<Inclusive<A,B>,Inclusive<T,U>,(A,B),(T,U)>.init(
				tryGet: { inclusive in inclusive.tryBoth },
				trySet: { tu in
					{ inclusive in
						inclusive.fold(
							onLeft: fconstant(nil),
							onCenter: fconstant(.center(tu.0,tu.1)),
							onRight: fconstant(nil))
					}
			})
		}

		public static func right<T>(to: T.Type) -> AffineFull<Inclusive<A,B>,Inclusive<A,T>,B,T> {
			return AffineFull<Inclusive<A,B>,Inclusive<A,T>,B,T>.init(
				tryGet: { inclusive in inclusive.tryRight },
				trySet: { t in
					{ inclusive in
						inclusive.fold(
							onLeft: fconstant(nil),
							onCenter: { a, _ in .center(a,t) },
							onRight: fconstant(.right(t)))
					}
			})
		}

		public static var leftSame: Affine<Inclusive<A,B>,A> {
			return left(to: A.self)
		}

		public static var centerSame: Affine<Inclusive<A,B>,(A,B)> {
			return center(to: (A.self,B.self))
		}

		public static var rightSame: Affine<Inclusive<A,B>,B> {
			return right(to: B.self)
		}
	}
}
