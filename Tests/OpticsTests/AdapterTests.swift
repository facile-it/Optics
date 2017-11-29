import XCTest
@testable import Optics
import SwiftCheck
import FunctionalKit

class AdapterTests: XCTestCase {

	func testComposedIsoWellBehaved() {

		property("FromTo") <- forAll { (l1: Int, r1: Int) in

			let p1 = TestProduct.init(l1, r1)

			let i1 = type(of: p1).iso.product
			let i2 = Couple<Int,Int>.iso.product.inverted
			let composed = i1..i2

			return IsoLaw.fromTo(whole: p1, iso: composed)
		}

		property("ToFrom") <- forAll { (l1: Int, r1: Int) in

            let p1 = TestProduct.init(l1, r1)
            
            let i1 = type(of: p1).iso.product.inverted
            let i2 = Couple<Int,Int>.iso.product
            let composed = i2..i1
            
            return IsoLaw.toFrom(part: p1, iso: composed)
		}
	}
}
