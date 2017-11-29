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
		property("'modify' works like injecting a value dependent on the previous tryGet") <- forAll { (p: TestProduct<Int,Int>, ar: ArrowOf<Int,Int>) in
			let a = ar.getArrow
			return TestProduct<Int,Int>.lens.first.modify(a)(p)
				== TestProduct<Int,Int>.lens.first.set(a(TestProduct<Int,Int>.lens.first.get(p)))(p)
		}
	}

	func testComposedLensWellBehaved() {
		property("SetGet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = TestProduct.init(l3, r3)
			let p2 = TestProduct.init(p3, r2)
			let p1 = TestProduct.init(l1, p2)

			let l1r = type(of: p1).lens.second
			let l2l = type(of: p2).lens.first
			let l3r = type(of: p3).lens.second

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.setGet(lens: joined, whole: p1, part: r3)
		}

		property("GetSet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = TestProduct(l3, r3)
			let p2 = TestProduct(p3, r2)
			let p1 = TestProduct(l1, p2)

			let l1r = type(of: p1).lens.second
			let l2l = type(of: p2).lens.first
			let l3r = type(of: p3).lens.second

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.getSet(lens: joined, whole: p1)
		}

		property("SetSet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let p3 = TestProduct(l3, r3)
			let p2 = TestProduct(p3, r2)
			let p1 = TestProduct(l1, p2)

			let l1r = type(of: p1).lens.second
			let l2l = type(of: p2).lens.first
			let l3r = type(of: p3).lens.second

			let joined = l1r.compose(l2l).compose(l3r)

			return LensLaw.setSet(lens: joined, whole: p1, part: r3)
		}
	}

	func testZipLensWellBehaved() {
		property("SetGet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(TestProduct<Int,Int>.lens.first, TestProduct<Int,Int>.lens.second)

			return LensLaw.setGet(lens: lens, whole: TestProduct(l1, r1), part: (l2,r2))
		}

		property("GetSet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(TestProduct<Int,Int>.lens.first, TestProduct<Int,Int>.lens.second)

			return LensLaw.getSet(lens: lens, whole: TestProduct(l1, r1))
		}

		property("SetSet") <- forAll { (l1: Int, r1: Int, l2: Int, r2: Int) in

			let lens = Lens.zip(TestProduct<Int,Int>.lens.first, TestProduct<Int,Int>.lens.second)

			return LensLaw.setSet(lens: lens, whole: TestProduct(l1, r1), part: (l2,r2))
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

    func testComposeLensOptional1() {
        property("Lens.compose for Lens<_,Optional>..Lens<_,_> respects GetSet") <- forAll { (whole: TestProductOptional<Int,TestProduct<Int,Int>>, defaultPart: TestProduct<Int,Int>) in
            let lens = TestProductOptional<Int,TestProduct<Int,Int>>.lens.second.compose(TestProduct<Int,Int>.lens.first, defaulting: defaultPart)
            
			return LensLaw.getSet(lens: lens, whole: whole)
        }

        property("Lens.compose for Lens<_,Optional>..Lens<_,_> respects SetGet") <- forAll { (whole: TestProductOptional<Int,TestProduct<Int,Int>>, part: OptionalOf<Int>, defaultPart: TestProduct<Int,Int>) in
			let lens = TestProductOptional<Int,TestProduct<Int,Int>>.lens.second.compose(TestProduct<Int,Int>.lens.first, defaulting: defaultPart)

			return LensLaw.setGet(lens: lens, whole: whole, part: part.getOptional)
        }

        property("Lens.compose for Lens<_,Optional>..Lens<_,_> respects SetSet") <- forAll { (whole: TestProductOptional<Int,TestProduct<Int,Int>>, part: OptionalOf<Int>, defaultPart: TestProduct<Int,Int>) in
			let lens = TestProductOptional<Int,TestProduct<Int,Int>>.lens.second.compose(TestProduct<Int,Int>.lens.first, defaulting: defaultPart)

			return LensLaw.setSet(lens: lens, whole: whole, part: part.getOptional)
        }
    }

    func testComposeLensOptional2() {
        property("Lens.compose for Lens<_,Optional>..Lens<Optional,_> respects GetSet") <- forAll { (whole: TestProductOptional<Int,TestProductOptional<Int,Int>>, defaultPart: TestProductOptional<Int,Int>) in
			let lens = TestProductOptional<Int,TestProductOptional<Int,Int>>.lens.second.compose(TestProductOptional<Int,Int>.lens.first, defaulting: defaultPart)

			return LensLaw.getSet(lens: lens, whole: whole)
        }

        property("Lens.compose for Lens<_,Optional>..Lens<Optional,_> respects GetSet") <- forAll { (whole: TestProductOptional<Int,TestProductOptional<Int,Int>>, part: OptionalOf<Int>, defaultPart: TestProductOptional<Int,Int>) in
			let lens = TestProductOptional<Int,TestProductOptional<Int,Int>>.lens.second.compose(TestProductOptional<Int,Int>.lens.first, defaulting: defaultPart)

			return LensLaw.setGet(lens: lens, whole: whole, part: part.getOptional)
        }

        property("Lens.compose for Lens<_,Optional>..Lens<Optional,_> respects SetSet") <- forAll { (whole: TestProductOptional<Int,TestProductOptional<Int,Int>>, part: OptionalOf<Int>, defaultPart: TestProductOptional<Int,Int>) in
			let lens = TestProductOptional<Int,TestProductOptional<Int,Int>>.lens.second.compose(TestProductOptional<Int,Int>.lens.first, defaulting: defaultPart)

			return LensLaw.setSet(lens: lens, whole: whole, part: part.getOptional)
        }
    }
}
