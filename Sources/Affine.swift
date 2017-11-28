#if !XCODE_BUILD
	import Operadics
#endif
import Abstract
import FunctionalKit

/// an Affine is a reference to some part of a data structure, where setting is failable when the data structure is not in appropriate state for that set

public protocol AffineType: OpticsType {
	var tryGet: (SType) -> AType? { get }
	var trySet: (BType) -> (SType) -> TType? { get }
}

public struct AffineFull<S,T,A,B>: AffineType {
	public typealias SType = S
	public typealias TType = T
	public typealias AType = A
	public typealias BType = B

	public let tryGet: (S) -> A? /// get the part, if possible
	public let trySet: (B) -> (S) -> T? /// set the part, if possible

	public init(tryGet: @escaping (S) -> A?, trySet: @escaping (B) -> (S) -> T?) {
		self.tryGet = tryGet
		self.trySet = trySet
	}
}

public typealias Affine<Whole,Part> = AffineFull<Whole,Whole,Part,Part>

extension AffineType {
	public func tryModify(_ transform: @escaping (AType) -> BType) -> (SType) -> TType? {
		return { s in
			self.tryGet(s).map(transform).flatMap { b in self.trySet(b)(s) }
		}
	}

	public func compose<OtherAffine>(_ other: OtherAffine) -> AffineFull<Self.SType,Self.TType,OtherAffine.AType,OtherAffine.BType> where OtherAffine: AffineType, OtherAffine.SType == Self.AType, OtherAffine.TType == Self.BType {
		return AffineFull<Self.SType,Self.TType,OtherAffine.AType,OtherAffine.BType>.init(
			tryGet: { s in self.tryGet(s).flatMap(other.tryGet) },
			trySet: { bp in
				{ s in
					self.tryGet(s).flatMap { a in other.trySet(bp)(a) }.flatMap { b in self.trySet(b)(s) }
				}
		})
	}
}

extension AffineType where TType == SType, AType == BType {
	public var set: (BType) -> (SType) -> TType {
		return { b in
			{ s in
				self.trySet(b)(s) ?? s
			}
		}
	}

	public func tryOver(_ transform: @escaping (AType) -> BType) -> (SType) -> TType {
		return { t in self.tryModify(transform)(t) ?? t }
	}

	public static func zip<A,B>(_ a: A, _ b: B) -> AffineFull<SType,TType,(A.AType,B.AType),(A.BType,B.BType)> where A: AffineType, B: AffineType, A.SType == SType, B.SType == SType, A.TType == TType, B.TType == TType, AType == (A.AType,B.AType), BType == (A.BType,B.BType)  {
		return AffineFull.init(
			tryGet: { s in Optional.zip(a.tryGet(s),b.tryGet(s)) },
			trySet: { (tuple) in
				{ s in b.set(tuple.1)(a.set(tuple.0)(s)) }
		})
	}
}

extension Array {
	public static func affine(at index: Int) -> Affine<Array,Element> {
		return Affine<Array,Element>.init(
			tryGet: { array in
				guard array.indices.contains(index) else { return nil }
				return array[index]
		},
			trySet: { element in
				{ array in
					guard array.indices.contains(index) else { return nil }
					var m = array
					_ = m.remove(at: index)
					m.insert(element, at: index)
					return array
				}
		})
	}
}
