/// A Lens is a reference to a subpart of some data structure

public protocol LensType: OpticsType {
	var get: (WholeType) -> PartType { get } /// get the "focused" part
	var set: (PartType) -> (WholeType) -> WholeType { get } /// set a new value for the "focused" part

	init(get: @escaping (WholeType) -> PartType, set: @escaping (PartType) -> (WholeType) -> WholeType)
}

public struct Lens<Whole,Part>: LensType {
	public typealias WholeType = Whole
	public typealias PartType = Part

	public let get: (Whole) -> Part
	public let set: (Part) -> (Whole) -> Whole

	public init(get: @escaping (Whole) -> Part, set: @escaping (Part) -> (Whole) -> Whole) {
		self.get = get
		self.set = set
	}
}

extension LensType {
	public func over(_ transform: @escaping (PartType) -> PartType) -> (WholeType) -> WholeType {
		return { whole in self.set(transform(self.get(whole)))(whole) }
	}

	public func compose<OtherLens>(_ other: OtherLens) -> Lens<WholeType,OtherLens.PartType> where OtherLens: LensType, OtherLens.WholeType == PartType {
		return Lens<WholeType,OtherLens.PartType>(
			get: { other.get(self.get($0)) },
			set: { (subpart: OtherLens.PartType) in
				{ (whole: WholeType) -> WholeType in
					self.set(other.set(subpart)(self.get(whole)))(whole)
				}
		})
	}
}

/// LensZip will hold the laws only if the involved lenses are focusing on different parts
public struct LensZip {
	public static func with<A, B>(_ a: A, _ b: B) -> Lens<A.WholeType,(A.PartType,B.PartType)> where A: LensType, B: LensType, A.WholeType == B.WholeType {
		return Lens<A.WholeType,(A.PartType,B.PartType)>(
			get: { (a.get($0),b.get($0)) },
			set: { parts in { whole in b.set(parts.1)(a.set(parts.0)(whole)) } })
	}

	public static func with<A, B, C>(_ a: A, _ b: B, _ c: C) -> Lens<A.WholeType,(A.PartType,B.PartType,C.PartType)> where A: LensType, B: LensType, C: LensType, A.WholeType == B.WholeType, B.WholeType == C.WholeType {
		return Lens<A.WholeType,(A.PartType,B.PartType,C.PartType)>(
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

//MARK: - Utilities

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

//MARK: - Lens Laws

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

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Whole, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Whole, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Optional<Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Optional<Whole>, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Array<Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Array<Whole>, SomeLens.PartType == Part {
		return lens.set(lens.get(whole))(whole) == whole
	}

	public static func getSet<Whole, Part, SomeLens>(lens: SomeLens, whole: Dictionary<String,Whole>, part: Part) -> Bool where Whole: Equatable, SomeLens: LensType, SomeLens.WholeType == Dictionary<String,Whole>, SomeLens.PartType == Part {
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
