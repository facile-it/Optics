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
extension Lens where SType == TType, AType == BType {
    public static func zip<A,B>(_ a: A, _ b: B) -> Lens<SType,(A.AType,B.AType)> where A: LensType, B: LensType, A.SType == A.TType, A.AType == A.BType, B.SType == B.TType, B.AType == B.BType, SType == A.SType, SType == B.SType {
        return Lens<SType,(A.AType,B.AType)>.init(
            get: { (a.get($0),b.get($0)) },
            set: { (tuple) in
                return { b.set(tuple.1)(a.set(tuple.0)($0)) }
        })
    }
    
    public static func zip<A,B,C>(_ a: A, _ b: B, _ c: C) -> Lens<SType,(A.AType,B.AType,C.AType)> where A: LensType, B: LensType, C: LensType, A.SType == A.TType, B.SType == B.TType, C.SType == C.TType, A.AType == A.BType, B.AType == B.BType, C.AType == C.BType, SType == A.SType, SType == B.SType, SType == C.SType {
        return Lens<SType,(A.AType,B.AType,C.AType)>.init(
            get: { (a.get($0),b.get($0),c.get($0)) },
            set: {  tuple in
                return { c.set(tuple.2)(b.set(tuple.1)(a.set(tuple.0)($0))) }
        })
    }
}

// MARK: - Utilities

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
	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Part) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Optional<Part>) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == Optional<Part>, SomeLens.BType == Optional<Part> {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Array<Part>) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == Array<Part>, SomeLens.BType == Array<Part> {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Dictionary<String,Part>) -> Bool where Part: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == Dictionary<String,Part>, SomeLens.BType == Dictionary<String,Part> {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func setGet<Whole, Part1, Part2, SomeLens>(lens: SomeLens, whole: Whole, part: (Part1,Part2)) -> Bool where Part1: Equatable, Part2: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == (Part1,Part2), SomeLens.BType == (Part1,Part2) {
		return lens.get(lens.set(part)(whole)) == part
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Optional<Whole>) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Optional<Whole>, SomeLens.TType == Optional<Whole>, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Array<Whole>) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Array<Whole>, SomeLens.TType == Array<Whole>, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Dictionary<String,Whole>) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Dictionary<String,Whole>, SomeLens.TType == Dictionary<String,Whole>, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Whole, SomeLens.TType == Whole, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Optional<Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Optional<Whole>, SomeLens.TType == Optional<Whole>, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Array<Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Array<Whole>, SomeLens.TType == Array<Whole>, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}

	public static func setSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Dictionary<String,Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.SType == Dictionary<String,Whole>, SomeLens.TType == Dictionary<String,Whole>, SomeLens.AType == Part, SomeLens.BType == Part {
		return lens.set(part)(whole) == lens.set(part)(lens.set(part)(whole))
	}
}
