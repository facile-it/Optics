import XCTest
@testable import Optics
import SwiftCheck
import FunctionalKit

class LensTests: XCTestCase {
	static var allTests = [
		("testOver", testOver),
		("testComposedLensWellBehaved", testComposedLensWellBehaved),
		("testZipLensWellBehaved", testZipLensWellBehaved),
		("testDictLensWellBehaved", testDictLensWellBehaved)
	]

	func testOver() {
		property("'modify' works like injecting a value dependent on the previous tryGet") <- forAll { (p: Pair<Int,Int>, ar: ArrowOf<Int,Int>) in
			let a = ar.getArrow
			return Pair<Int,Int>.lens.a.modify(a)(p)
				== Pair<Int,Int>.lens.a.set(a(Pair<Int,Int>.lens.a.get(p)))(p)
		}
	}

	func testComposedLensWellBehaved() {
		property("SetGet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = Pair(a: l3, b: r3)
			let p2 = Pair(a: p3, b: r2)
			let p1 = Pair(a: l1, b: p2)

			let l1r = type(of: p1).lens.b
			let l2l = type(of: p2).lens.a
			let l3r = type(of: p3).lens.b

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.setGet(lens: joined, whole: p1, part: r3)
		}

		property("GetSet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = Pair(a: l3, b: r3)
			let p2 = Pair(a: p3, b: r2)
			let p1 = Pair(a: l1, b: p2)

			let l1r = type(of: p1).lens.b
			let l2l = type(of: p2).lens.a
			let l3r = type(of: p3).lens.b

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.getSet(lens: joined, whole: p1)
		}

		property("SetSet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = Pair(a: l3, b: r3)
			let p2 = Pair(a: p3, b: r2)
			let p1 = Pair(a: l1, b: p2)

			let l1r = type(of: p1).lens.b
			let l2l = type(of: p2).lens.a
			let l3r = type(of: p3).lens.b

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.setSet(lens: joined, whole: p1, part: r3)
		}
	}

	func testZipLensWellBehaved() {
		property("SetGet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(Pair<Int,Int>.lens.a, Pair<Int,Int>.lens.b)

			return LensLaw.setGet(lens: lens, whole: Pair(a: l1, b: r1), part: (l2,r2))
		}

		property("GetSet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(Pair<Int,Int>.lens.a, Pair<Int,Int>.lens.b)

			return LensLaw.getSet(lens: lens, whole: Pair(a: l1, b: r1))
		}

		property("SetSet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(Pair<Int,Int>.lens.a, Pair<Int,Int>.lens.b)

			return LensLaw.setSet(lens: lens, whole: Pair(a: l1, b: r1), part: (l2,r2))
		}
	}

	func testDictLensWellBehaved() {
		property("SetGet") <- forAll { (ad: DictionaryOf<String,Int>, av: OptionalOf<Int>) in
			let dict = ad.getDictionary
			guard let key = dict.keys.first else { return true }
			let value = av.getOptional
			let lens = Dictionary<String,Int>.lens(at: key)
			return LensLaw.setGet(lens: lens, whole: dict, part: value)
		}

		property("GetSet") <- forAll { (ad: DictionaryOf<String,Int>, av: OptionalOf<Int>) in
			let dict = ad.getDictionary
			guard let key = dict.keys.first else { return true }
			let lens = Dictionary<String,Int>.lens(at: key)
			return LensLaw.getSet(lens: lens, whole: dict)
		}

		property("SetSet") <- forAll { (ad: DictionaryOf<String,Int>, av: OptionalOf<Int>) in
			let dict = ad.getDictionary
			guard let key = dict.keys.first else { return true }
			let value = av.getOptional
			let lens = Dictionary<String,Int>.lens(at: key)
			return LensLaw.setSet(lens: lens, whole: dict, part: value)
		}
	}

//    func testComposeLensOptional1() {
//        property("Lens.compose for Lens<_,Optional>..Lens<_,_> respects GetSet") <- forAll { (whole: OptionalPair<Int,Pair<Int,Int>>, part: OptionalOf<Int>, defaultPart: Pair<Int,Int>) in
//            LensLaw.getSet(
//                lens: OptionalPair<Int,Pair<Int,Int>>.lens.b.compose(Pair<Int,Int>.lens.a, injecting: defaultPart),
//                whole: whole,
//                part: part.getOptional)
//        }
//
//        property("Lens.compose for Lens<_,Optional>..Lens<_,_> respects SetGet") <- forAll { (whole: OptionalPair<Int,Pair<Int,Int>>, part: OptionalOf<Int>, defaultPart: Pair<Int,Int>) in
//            LensLaw.setGet(
//                lens: OptionalPair<Int,Pair<Int,Int>>.lens.b.compose(Pair<Int,Int>.lens.a, injecting: defaultPart),
//                whole: whole,
//                part: part.getOptional)
//        }
//
//        property("Lens.compose for Lens<_,Optional>..Lens<_,_> respects SetSet") <- forAll { (whole: OptionalPair<Int,Pair<Int,Int>>, part: OptionalOf<Int>, defaultPart: Pair<Int,Int>) in
//            LensLaw.setSet(
//                lens: OptionalPair<Int,Pair<Int,Int>>.lens.b.compose(Pair<Int,Int>.lens.a, injecting: defaultPart),
//                whole: whole,
//                part: part.getOptional)
//        }
//    }
//
//    func testComposeLensOptional2() {
//        property("Lens.compose for Lens<_,Optional>..Lens<Optional,_> respects GetSet") <- forAll { (whole: OptionalPair<Int,OptionalPair<Int,Int>>, part: OptionalOf<Int>, defaultPart: OptionalPair<Int,Int>) in
//            LensLaw.getSet(
//                lens: OptionalPair<Int,OptionalPair<Int,Int>>.lens.b.compose(OptionalPair<Int,Int>.lens.a, injecting: defaultPart),
//                whole: whole,
//                part: part.getOptional)
//        }
//
//        property("Lens.compose for Lens<_,Optional>..Lens<Optional,_> respects GetSet") <- forAll { (whole: OptionalPair<Int,OptionalPair<Int,Int>>, part: OptionalOf<Int>, defaultPart: OptionalPair<Int,Int>) in
//            return LensLaw.setGet(
//                lens: OptionalPair<Int,OptionalPair<Int,Int>>.lens.b.compose(OptionalPair<Int,Int>.lens.a, injecting: defaultPart),
//                whole: whole,
//                part: part.getOptional)
//        }
//
//        property("Lens.compose for Lens<_,Optional>..Lens<Optional,_> respects SetSet") <- forAll { (whole: OptionalPair<Int,OptionalPair<Int,Int>>, part: OptionalOf<Int>, defaultPart: OptionalPair<Int,Int>) in
//            LensLaw.setSet(
//                lens: OptionalPair<Int,OptionalPair<Int,Int>>.lens.b.compose(OptionalPair<Int,Int>.lens.a, injecting: defaultPart),
//                whole: whole,
//                part: part.getOptional)
//        }
//    }
}
