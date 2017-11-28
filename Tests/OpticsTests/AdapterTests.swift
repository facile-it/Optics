import XCTest
@testable import Optics
import SwiftCheck
import FunctionalKit

class AdapterTests: XCTestCase {

	func testComposedIsoWellBehaved() {

		property("FromTo") <- forAll { (l1: Int, l2: Int, r2: Int) in

			let p1 = Pair.init(a: l1, b: Pair.init(a: l2, b: r2))

			let i1 = type(of: p1.b).iso.couple
			let i2 = Couple<Int,Int>.iso.pair
			let composed = i1..i2

			return IsoLaw.fromTo(whole: p1.b, iso: composed)
		}

		property("ToFrom") <- forAll { (l1: Int, l2: Int, r2: Int) in

			let p1 = Pair.init(a: l1, b: Pair.init(a: l2, b: r2))

			let i1 = type(of: p1.b).iso.couple
			let i2 = Couple<Int,Int>.iso.pair
			let composed = i1..i2

			return IsoLaw.toFrom(part: p1.b, iso: composed)
		}
	}
}
