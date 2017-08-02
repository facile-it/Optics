import XCTest
@testable import Optics
import SwiftCheck

class LensTests: XCTestCase {
	static var allTests = [
		("testOver", testOver),
		("testComposedLensWellBehaved", testComposedLensWellBehaved),
		("testZipLensWellBehaved", testZipLensWellBehaved),
		("testDictLensWellBehaved", testDictLensWellBehaved)
	]

	func testOver() {
		property("'over' works like injecting a value dependent on the previous tryGet") <- forAll { (ap: ArbitraryProduct<Int,Int>, ar: ArrowOf<Int,Int>) in
			let p = ap.get
			let a = ar.getArrow
			return Product<Int,Int>.leftLens.over(a)(p)
				== Product<Int,Int>.leftLens.set(a(Product<Int,Int>.leftLens.get(p)))(p)
		}
	}

	func testComposedLensWellBehaved() {
		property("SetGet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = Product(left: l3, right: r3)
			let p2 = Product(left: p3, right: r2)
			let p1 = Product(left: l1, right: p2)

			let l1r = type(of: p1).rightLens
			let l2l = type(of: p2).leftLens
			let l3r = type(of: p3).rightLens

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.setGet(lens: joined, whole: p1, part: r3)
		}

		property("GetSet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = Product(left: l3, right: r3)
			let p2 = Product(left: p3, right: r2)
			let p1 = Product(left: l1, right: p2)

			let l1r = type(of: p1).rightLens
			let l2l = type(of: p2).leftLens
			let l3r = type(of: p3).rightLens

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.getSet(lens: joined, whole: p1, part: r3)
		}

		property("SetSet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = Product(left: l3, right: r3)
			let p2 = Product(left: p3, right: r2)
			let p1 = Product(left: l1, right: p2)

			let l1r = type(of: p1).rightLens
			let l2l = type(of: p2).leftLens
			let l3r = type(of: p3).rightLens

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.setSet(lens: joined, whole: p1, part: r3)
		}
	}

	func testZipLensWellBehaved() {
		property("SetGet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(Product<Int,Int>.leftLens, Product<Int,Int>.rightLens)

			return LensLaw.setGet(lens: lens, whole: Product(left: l1, right: r1), part: (l2,r2))
		}

		property("GetSet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(Product<Int,Int>.leftLens, Product<Int,Int>.rightLens)

			return LensLaw.getSet(lens: lens, whole: Product(left: l1, right: r1), part: (l2,r2))
		}

		property("SetSet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(Product<Int,Int>.leftLens, Product<Int,Int>.rightLens)

			return LensLaw.setSet(lens: lens, whole: Product(left: l1, right: r1), part: (l2,r2))
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
			let value = av.getOptional
			let lens = Dictionary<String,Int>.lens(at: key)
			return LensLaw.getSet(lens: lens, whole: dict, part: value)
		}

		property("SetSet") <- forAll { (ad: DictionaryOf<String,Int>, av: OptionalOf<Int>) in
			let dict = ad.getDictionary
			guard let key = dict.keys.first else { return true }
			let value = av.getOptional
			let lens = Dictionary<String,Int>.lens(at: key)
			return LensLaw.setSet(lens: lens, whole: dict, part: value)
		}
	}
}
