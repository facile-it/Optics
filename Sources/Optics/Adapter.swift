import Abstract
import FunctionalKit

/// An Adapter establishes a one-to-one relationship from the Whole values to the Part values; the simplified case is an Iso, i.e. an isomorphism, and should behave as such.

public protocol AdapterType: OpticsType {
	var from: (SType) -> AType { get }
	var to: (BType) -> TType { get }
}

public struct Adapter<S,T,A,B>: AdapterType {
	public typealias SType = S
	public typealias TType = T
	public typealias AType = A
	public typealias BType = B

	public let from: (S) -> A
	public let to: (B) -> T

	public init(from: @escaping (S) -> A, to: @escaping (B) -> T) {
		self.from = from
		self.to = to
	}
}

public typealias Iso<Whole,Part> = Adapter<Whole,Whole,Part,Part>

extension AdapterType {
	public func compose <OtherAdapter> (_ other: OtherAdapter) -> Adapter<SType,TType,OtherAdapter.AType,OtherAdapter.BType> where OtherAdapter: AdapterType, OtherAdapter.SType == AType, OtherAdapter.TType == BType {
		return Adapter.init(
			from: self.from..other.from,
			to: other.to..self.to)
	}

	public static func .. <OtherAdapter> (lhs: Self, rhs: OtherAdapter) -> Adapter<SType,TType,OtherAdapter.AType,OtherAdapter.BType> where OtherAdapter: AdapterType, OtherAdapter.SType == AType, OtherAdapter.TType == BType {
		return lhs.compose(rhs)
	}

	public var inverted: Adapter<BType,AType,TType,SType> {
		return Adapter.init(from: to, to: from)
	}

	public func under(_ transform: @escaping (TType) -> SType) -> (BType) -> AType {
		return to..transform..from
	}

	public var toLens: LensFull<SType,TType,AType,BType> {
		return LensFull.init(get: from, set: to..fconstant)
	}

	public static func .. <OtherLens> (lhs: Self, rhs: OtherLens) -> LensFull<SType,TType,OtherLens.AType,OtherLens.BType> where OtherLens: LensType, OtherLens.SType == AType, OtherLens.TType == BType {
		return lhs.toLens.compose(rhs)
	}

	public static func .. <OtherLens> (lhs: OtherLens, rhs: Self) -> LensFull<OtherLens.SType,OtherLens.TType,AType,BType> where OtherLens: LensType, OtherLens.AType == SType, OtherLens.BType == TType {
		return lhs.compose(rhs.toLens)
	}

	public var toPrism: PrismFull<SType,TType,AType,BType> {
		return PrismFull.init(tryGet: from..Optional.init, inject: to)
	}

	public static func .. <OtherPrism> (lhs: Self, rhs: OtherPrism) -> PrismFull<SType,TType,OtherPrism.AType,OtherPrism.BType> where OtherPrism: PrismType, OtherPrism.SType == AType, OtherPrism.TType == BType {
		return lhs.toPrism.compose(rhs)
	}

	public static func .. <OtherPrism> (lhs: OtherPrism, rhs: Self) -> PrismFull<OtherPrism.SType,OtherPrism.TType,AType,BType> where OtherPrism: PrismType, OtherPrism.AType == SType, OtherPrism.BType == TType {
		return lhs.compose(rhs.toPrism)
	}
}

extension AdapterType where SType == TType, AType == BType {
	public static func zip <A,B> (_ a: A, _ b: B) -> Adapter<SType,TType,(A.AType,B.AType),(A.BType,B.BType)> where A: AdapterType, B: AdapterType, A.SType == SType, B.SType == SType, A.TType == TType, B.TType == TType, AType == (A.AType,B.AType), BType == (A.BType,B.BType) {
		return Adapter.init(
			from: fduplicate..fzip(a.from,b.from),
			to: fzip(a.to,b.to)..ffirst)
	}
}

// MARK: - Adapter Laws

/*:
## Enforcing Iso laws

An `Iso` should actually represent an isomorphism: this means that there's a one-to-one correspondence between instances of `Whole` and `Part` and I can always obtain a `Part` from a `Whole` and viceversa without gain or loss of information.

In other words this means that calling `from..to` on a `Whole` returns the same `Whole`, and `to..from` on a `Part` returns the same `Part`.
:*/

public enum IsoLaw {
	public static func fromTo<SomeIso>(whole: SomeIso.SType, iso: SomeIso) -> Bool where SomeIso: AdapterType, SomeIso.SType == SomeIso.TType, SomeIso.AType == SomeIso.BType, SomeIso.SType: Equatable {
		return (whole |> iso.from |> iso.to) == whole
	}

	public static func tofrom<SomeIso>(part: SomeIso.AType, iso: SomeIso) -> Bool where SomeIso: AdapterType, SomeIso.SType == SomeIso.TType, SomeIso.AType == SomeIso.BType, SomeIso.AType: Equatable {
		return (part |> iso.to |> iso.from) == part
	}
}
