import XCTest
@testable import Optics
import SwiftCheck
import FunctionalKit

class PrismTests: XCTestCase {
	static var allTests = [
		("testModify", testModify),
		("testComposedPrismWellBehaved", testComposedPrismWellBehaved)
	]

	func testModify() {
		property("'tryModify' works like injecting a value dependent on the previous tryGet") <- forAll { (s: TestCoproduct<Int,Int>, ar: ArrowOf<Int,Int>) in
			let a = ar.getArrow
			return TestCoproduct<Int,Int>.prism.left.tryModify(a)(s)
				== TestCoproduct<Int,Int>.prism.left.tryGet(s).map(a).map(TestCoproduct<Int,Int>.prism.left.inject)
		}
	}

	func testComposedPrismWellBehaved() {
		property("InjectTryGet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let s3 = TestCoproduct<Int,Int>.right(r3)
			let s2 = TestCoproduct<TestCoproduct<Int,Int>,Int>.left(s3)
			let s1 = TestCoproduct<Int,TestCoproduct<TestCoproduct<Int,Int>,Int>>.right(s2)

			let l1r = type(of: s1).prism.right
			let l2l = type(of: s2).prism.left
			let l3r = type(of: s3).prism.right

			let joined = l1r.compose(l2l).compose(l3r)

			return PrismLaw.injectTryGet(prism: joined, part: r3)
		}

		property("TryGetInject") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let s3 = TestCoproduct<Int,Int>.right(r3)
			let s2 = TestCoproduct<TestCoproduct<Int,Int>,Int>.left(s3)
			let s1 = TestCoproduct<Int,TestCoproduct<TestCoproduct<Int,Int>,Int>>.right(s2)

			let l1r = type(of: s1).prism.right
			let l2l = type(of: s2).prism.left
			let l3r = type(of: s3).prism.right

			let joined = l1r.compose(l2l).compose(l3r)

			return PrismLaw.tryGetInject(prism: joined, whole: s1, part: r3)
		}
	}
}
