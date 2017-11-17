import Monads
import Abstract
import Functional

/// A Lens is a reference to a subpart of some data structure

public protocol LensType: OpticsType {
    var get: (SType) -> AType { get }
    var set: (BType) -> (SType) -> TType { get }
}

public struct LensP<S,T,A,B>: LensType {
    public typealias SType = S
    public typealias TType = T
    public typealias AType = A
    public typealias BType = B
    
    public let get: (S) -> A
    public let set: (B) -> (S) -> T
    
    public init(get: @escaping (S) -> A, set: @escaping (B) -> (S) -> T) {
        self.get = get
        self.set = set
    }
}

public typealias Lens<Whole,Part> = LensP<Whole,Whole,Part,Part>

extension LensType {
    public func modify(_ transform: @escaping (AType) -> (BType)) -> (SType) -> TType {
        return { s in self.set(transform(self.get(s)))(s) }
    }
    
    public func compose<OtherLens>(_ other: OtherLens) -> LensP<Self.SType,Self.TType,OtherLens.AType,OtherLens.BType> where OtherLens: LensType, OtherLens.SType == Self.AType, OtherLens.TType == Self.BType {
        return LensP<Self.SType,Self.TType,OtherLens.AType,OtherLens.BType>.init(
            get: { other.get(self.get($0)) },
            set: { bp in
                return { s in
                    return self.set(other.set(bp)(self.get(s)))(s)
                }
        })
    }
    
    public static func .. <OtherLens>(left: Self, right: OtherLens) -> LensP<Self.SType,Self.TType,OtherLens.AType,OtherLens.BType> where OtherLens: LensType, OtherLens.SType == Self.AType, OtherLens.TType == Self.BType {
        return left.compose(right)
    }
}

/// zipped lenses will hold the laws only if the involved lenses are focusing on different parts
extension Lens {
	public static func zip<A,B>(_ a: A, _ b: B) -> Lens<WholeType,(A.PartType,B.PartType)> where A: LensType, B: LensType, WholeType == A.WholeType, WholeType == B.WholeType, PartType == (A.PartType,B.PartType) {
		return Lens<WholeType,(A.PartType,B.PartType)>(
			get: { (a.get($0),b.get($0)) },
			set: { parts in { whole in b.set(parts.1)(a.set(parts.0)(whole)) } })
	}

	public static func zip<A, B, C>(_ a: A, _ b: B, _ c: C) -> Lens<WholeType,(A.PartType,B.PartType,C.PartType)> where A: LensType, B: LensType, C: LensType, WholeType == A.WholeType, WholeType == B.WholeType, WholeType == C.WholeType, PartType == (A.PartType,B.PartType,C.PartType) {
		return Lens<WholeType,(A.PartType,B.PartType,C.PartType)>(
			get: { (a.get($0),b.get($0),c.get($0)) },
			set: { parts in { whole in c.set(parts.2)(b.set(parts.1)(a.set(parts.0)(whole))) } })
	}
}

/// A BoundLens is a reference to a subpart of a specific data structure, to which it's "bound"

public struct BoundLens<Whole,Part> {
	fileprivate let value: Whole
	fileprivate let lens: Lens<Whole,Part>

	public init<AssociatedLens>(value: Whole, lens: AssociatedLens) where AssociatedLens: LensType, AssociatedLens.WholeType == Whole, AssociatedLens.PartType == Part {
		self.value = value
		self.lens = Lens(get: lens.get, set: lens.set)
	}
}

extension BoundLens {
	public var unmodified: Whole {
		return value
	}

	public var get: Part {
		return lens.get(value)
	}

	public var set: (Part) -> Whole {
		return { self.lens.set($0)(self.value) }
	}

	public func over(_ transform: @escaping (Part) -> Part) -> Whole {
		return lens.over(transform)(value)
	}
}

extension LensType {
	public func bind(to value: WholeType) -> BoundLens<WholeType,PartType> {
		return BoundLens(value: value, lens: self)
	}
}

// MARK: - Utilities

extension BoundLens where Part: Equatable {
	@discardableResult
	public func should(be requiredPart: Part) -> Whole {
		if get != requiredPart {
			return set(requiredPart)
		} else {
			return unmodified
		}
	}
}

extension Dictionary {
	public static func lens(at key: Key) -> Lens<Dictionary,Value?> {
		return Lens<Dictionary,Value?>(
			get: { $0[key] },
			set: { part in { whole in var m_dict = whole; m_dict[key] = part; return m_dict } })
	}
}

// MARK: Lenses on Optionals

extension LensType where PartType: OptionalType {
	public func compose<OtherLens>(_ other: OtherLens, injecting defaultPart: @autoclosure @escaping () -> PartType.ElementType) -> Lens<WholeType,Optional<OtherLens.PartType>> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType {
		return Lens<WholeType,Optional<OtherLens.PartType>>.init(
			get: { whole in self.get(whole).run(ifSome: { other.get($0) }, ifNone: { nil }) },
			set: { optionalPart in { whole in
				optionalPart.run(
					ifSome: { self.set(PartType.pure(other.set($0)(self.get(whole).get(or: defaultPart()))))(whole) },
					ifNone: { self.set(PartType.init())(whole) }) } })
	}

	public static func .. <OtherLens>(left: Self, right: (OtherLens, injecting: () -> PartType.ElementType))
		-> Lens<WholeType,Optional<OtherLens.PartType>> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType {
			return left.compose(right.0, injecting: right.injecting())
	}

	public func compose<OtherLens>(_ other: OtherLens, injecting defaultPart: @autoclosure @escaping () -> PartType.ElementType) -> Lens<WholeType,OtherLens.PartType> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType, OtherLens.PartType: OptionalType {
		return Lens<WholeType,OtherLens.PartType>.init(
			get: { whole in
				self.get(whole).run(
					ifSome: { other.get($0) },
					ifNone: { OtherLens.PartType.init() })
		},
			set: { optionalPart in { whole in
				optionalPart.run(
					ifSome: { _ in self.set(PartType.pure(other.set(optionalPart)(self.get(whole).get(or: defaultPart()))))(whole) },
					ifNone: {
						self.get(whole).run(
							ifSome: { self.set(PartType.pure(other.set(OtherLens.PartType.init())($0)))(whole) },
							ifNone: { whole }) }) } })
	}

	public static func .. <OtherLens>(left: Self, right: (OtherLens, injecting: () -> PartType.ElementType))
		-> Lens<WholeType,OtherLens.PartType> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType, OtherLens.PartType: OptionalType {
			return left.compose(right.0, injecting: right.injecting())
	}
}

extension LensType where PartType: OptionalType, PartType.ElementType: Monoid {
	public func compose<OtherLens>(_ other: OtherLens) -> Lens<WholeType,Optional<OtherLens.PartType>> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType {
		return self.compose(other, injecting: .empty)
	}

	public func compose<OtherLens>(_ other: OtherLens) -> Lens<WholeType,OtherLens.PartType> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType, OtherLens.PartType: OptionalType {
		return self.compose(other, injecting: .empty)
	}

	public static func .. <OtherLens>(left: Self, right: OtherLens) -> Lens<WholeType,Optional<OtherLens.PartType>> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType {
		return left.compose(right)
	}

	public static func .. <OtherLens>(left: Self, right: OtherLens) -> Lens<WholeType,OtherLens.PartType> where OtherLens: LensType, OtherLens.WholeType == PartType.ElementType, OtherLens.PartType: OptionalType {
		return left.compose(right)
	}
}

// MARK: - Lens Laws

/*:
## Enforcing lens laws

Lenses are not just bags of syntax: for a lens to make sense it's important that some invariants are respected.

A Lens is defined as just a couple of functions, but what matters are the "semantics" attached to those lenses.

For a lens to be "well-behaved" it has to follow two invariants:

- SetGet: if a value is `set` through a lens, when you `get` it you obtain the same value;
- GetSet: if a value is `get` through a lens, `set`ting it back doesn't change the `whole` structure.

There's also and additional law (for a "very well-behaved lens) that, if enforced, guarantees that the `set` operation is idempotent:

- SetSet: if a value is `set` and then is `set` again, the `whole` is the same as the one after the first `set`.

When defining a Lens, it's important to test it after these laws with a property-based testing framework.
:*/

public struct LensLaw {
	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Part) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Part {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Optional<Part>) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Optional<Part> {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Array<Part>) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Array<Part> {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Dictionary<String,Part>) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Dictionary<String,Part> {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part1, Part2, SomeLens>(lens: SomeLens, whole: Whole, part: (Part1,Part2)) -> Bool where Part1: Equatable, Part2: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == (Part1,Part2) {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Optional<Whole>) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Optional<Whole>, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Array<Whole>) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Array<Whole>, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Dictionary<String,Whole>) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Dictionary<String,Whole>, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Optional<Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Optional<Whole>, SomeLens.PartType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Array<Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Array<Whole>, SomeLens.PartType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Dictionary<String,Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Dictionary<String,Whole>, SomeLens.PartType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}
}
