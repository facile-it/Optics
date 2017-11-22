import XCTest
@testable import Optics
import SwiftCheck

class PrismTests: XCTestCase {
	static var allTests = [
		("testModify", testModify),
		("testComposedPrismWellBehaved", testComposedPrismWellBehaved)
	]

	func testModify() {
		property("'tryModify' works like injecting a value dependent on the previous tryGet") <- forAll { (as_: ArbitrarySum<Int,Int>, ar: ArrowOf<Int,Int>) in
			let s = as_.get
			let a = ar.getArrow
			return Sum<Int,Int>.leftPrism.tryModify(a)(s)
				== Sum<Int,Int>.leftPrism.tryGet(s).map(a).map(Sum<Int,Int>.leftPrism.inject)
		}
	}

	func testComposedPrismWellBehaved() {
		property("InjectTryGet") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let s3 = Sum<Int,Int>.right(r3)
			let s2 = Sum<Sum<Int,Int>,Int>.left(s3)
			let s1 = Sum<Int,Sum<Sum<Int,Int>,Int>>.right(s2)

			let l1r = type(of: s1).rightPrism
			let l2l = type(of: s2).leftPrism
			let l3r = type(of: s3).rightPrism

			let joined = l1r.compose(l2l).compose(l3r)

			return PrismLaw.injectTryGet(prism: joined, part: r3)
		}

		property("TryGetInject") <- forAll { (l1: Int, r2: Int, l3: Int, r3: Int) in
			let s3 = Sum<Int,Int>.right(r3)
			let s2 = Sum<Sum<Int,Int>,Int>.left(s3)
			let s1 = Sum<Int,Sum<Sum<Int,Int>,Int>>.right(s2)

			let l1r = type(of: s1).rightPrism
			let l2l = type(of: s2).leftPrism
			let l3r = type(of: s3).rightPrism

			let joined = l1r.compose(l2l).compose(l3r)

			return PrismLaw.tryGetInject(prism: joined, whole: s1, part: r3)
		}
	}
}
