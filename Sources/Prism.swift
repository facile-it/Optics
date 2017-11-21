import Functional

/// A Prism is a reference to a component of a sum type

public protocol PrismType: OpticsType {
	var tryGet: (SType) -> AType? { get }
	var inject: (BType) -> TType { get }

	init(tryGet: @escaping (SType) -> AType?, inject: @escaping (BType) -> TType)
}

public struct PrismP<S,T,A,B>: PrismType {
	public typealias SType = S
	public typealias TType = T
    public typealias AType = A
    public typealias BType = B

	public let tryGet: (S) -> A? /// get the part, if possible
	public let inject: (B) -> T /// changes the value to reflect the part that's injected in

	public init(tryGet: @escaping (S) -> A?, inject: @escaping (B) -> T) {
		self.tryGet = tryGet
		self.inject = inject
	}
}

public typealias Prism<Whole,Part> = PrismP<Whole,Whole,Part,Part>

extension PrismType {
	public func tryOver(_ transform: @escaping (AType) -> BType) -> (SType) -> TType? {
        return { s in
            guard let a = self.tryGet(s) else { return nil }
            return self.inject(transform(a))
        }
	}
    
    public func isCase(_ whole: SType) -> Bool {
        return tryGet(whole).isNotNil
    }

	public func compose<OtherPrism>(_ other: OtherPrism) -> PrismP<Self.SType,Self.TType,OtherPrism.AType,OtherPrism.BType> where OtherPrism: PrismType, OtherPrism.SType == Self.AType, OtherPrism.TType == Self.BType {
		return PrismP<Self.SType,Self.TType,OtherPrism.AType,OtherPrism.BType> (
			tryGet: { self.tryGet($0).flatMap(other.tryGet) },
			inject: { self.inject(other.inject($0)) })
	}

	public static func .. <OtherPrism>(left: Self, right: OtherPrism) -> PrismP<Self.SType,Self.TType,OtherPrism.AType,OtherPrism.BType> where OtherPrism: PrismType, OtherPrism.SType == Self.AType, OtherPrism.TType == Self.BType {
		return left.compose(right)
	}
}

/// zipped prisms will hold the laws only if the involved prisms are focusing on different parts
extension Prism {
	public static func zip<A,B>(_ a: A, _ b: B) -> Prism<SType,Either<A.AType,B.AType>> where A: PrismType, B: PrismType, SType == A.SType, SType == B.SType, A.SType == A.TType, A.AType == A.BType, B.SType == B.TType, B.AType == B.BType {
		return Prism<SType,Either<A.AType,B.AType>>(
			tryGet: { a.tryGet($0).map(Either.left) ?? b.tryGet($0).map(Either.right) },
			inject: { $0.fold(onLeft: a.inject, onRight: b.inject) })
	}
}

/// A BoundPrism is a reference to a component of a specific sum type, to which it's "bound"

public struct BoundPrism<Whole,Part> {
	public let value: Whole
	public let prism: Prism<Whole,Part>
	public init<AssociatedPrism>(value: Whole, prism: AssociatedPrism) where AssociatedPrism: PrismType, AssociatedPrism.WholeType == Whole, AssociatedPrism.PartType == Part {
		self.value = value
		self.prism = Prism(tryGet: prism.tryGet, inject: prism.inject)
	}
}

extension BoundPrism {
	public var tryGet: Part? {
		return prism.tryGet(value)
	}

	public var inject: (Part) -> Whole {
		return { self.prism.inject($0) }
	}

	public func tryOver(_ transform: @escaping (Part) -> Part) -> Whole? {
		return prism.tryOver(transform)(value)
	}
}

extension PrismType {
	public func bind(to value: WholeType) -> BoundPrism<WholeType,PartType> {
		return BoundPrism(value: value, prism: self)
	}
}

/*:
## Enforcing prism laws

Much like prismes, prisms have their laws that have to be enforced to describe a "well-behaved" prism.

For a prism to be "well-behaved" it has to follow two invariants:

- InjectTryGet: if a value is `inject` through a prism, when you `tryGet` it you obtain the same value;
- TryGetInject: if a value is `tryGet` through a prism, and the value exists, `inject`ting it back recreates the same `whole` structure.

When defining a Prism, it's important to test it after these laws with a property-based testing framework.
:*/

public struct PrismLaw {

	public static func injectTryGet<Whole, Part, SomePrism>(prism: SomePrism, whole: Whole, part: Part) -> Bool where Part: Equatable, SomePrism: PrismType, SomePrism.WholeType == Whole, SomePrism.PartType == Part {
		guard let got = prism.tryGet(prism.inject(part)) else { return false }
		return  got == part
	}

	public static func injectTryGet<Whole, Part, SomePrism>(prism: SomePrism, whole: Whole, part: Optional<Part>) -> Bool where Part: Equatable, SomePrism: PrismType, SomePrism.WholeType == Whole, SomePrism.PartType == Optional<Part> {
		guard let got = prism.tryGet(prism.inject(part)) else { return false }
		return  got == part
	}

	public static func injectTryGet<Whole, Part, SomePrism>(prism: SomePrism, whole: Whole, part: Array<Part>) -> Bool where Part: Equatable, SomePrism: PrismType, SomePrism.WholeType == Whole, SomePrism.PartType == Array<Part> {
		guard let got = prism.tryGet(prism.inject(part)) else { return false }
		return  got == part
	}

	public static func injectTryGet<Whole, Part, SomePrism>(prism: SomePrism, whole: Whole, part: Dictionary<String,Part>) -> Bool where Part: Equatable, SomePrism: PrismType, SomePrism.WholeType == Whole, SomePrism.PartType == Dictionary<String,Part> {
		guard let got = prism.tryGet(prism.inject(part)) else { return false }
		return  got == part
	}

	public static func tryGetInject<Whole, Part, SomePrism>(prism: SomePrism, whole: Whole, part: Part) -> Bool where Whole: Equatable, SomePrism: PrismType, SomePrism.WholeType == Whole, SomePrism.PartType == Part {
		guard let value = prism.tryGet(whole) else { return true }
		return prism.inject(value) == whole
	}

	public static func tryGetInject<Whole, Part, SomePrism>(prism: SomePrism, whole: Optional<Whole>, part: Part) -> Bool where Whole: Equatable, SomePrism: PrismType, SomePrism.WholeType == Optional<Whole>, SomePrism.PartType == Part {
		guard let value = prism.tryGet(whole) else { return true }
		return prism.inject(value) == whole
	}

	public static func tryGetInject<Whole, Part, SomePrism>(prism: SomePrism, whole: Array<Whole>, part: Part) -> Bool where Whole: Equatable, SomePrism: PrismType, SomePrism.WholeType == Array<Whole>, SomePrism.PartType == Part {
		guard let value = prism.tryGet(whole) else { return true }
		return prism.inject(value) == whole
	}

	public static func tryGetInject<Whole, Part, SomePrism>(prism: SomePrism, whole: Dictionary<String,Whole>, part: Part) -> Bool where Whole: Equatable, SomePrism: PrismType, SomePrism.WholeType == Dictionary<String,Whole>, SomePrism.PartType == Part {
		guard let value = prism.tryGet(whole) else { return true }
		return prism.inject(value) == whole
	}

	public static func tryGetInject<Whole1, Whole2, Part, SomePrism>(prism: SomePrism, whole: (Whole1,Whole2), part: Part) -> Bool where Whole1: Equatable, Whole2: Equatable, SomePrism: PrismType, SomePrism.WholeType == (Whole1,Whole2), SomePrism.PartType == Part {
		guard let value = prism.tryGet(whole) else { return true }
		return prism.inject(value) == whole
	}
}
