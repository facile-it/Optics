import XCTest
@testable import Optics
import SwiftCheck
import FunctionalKit

class AdapterTests: XCTestCase {

	func testComposedIsoWellBehaved() {

		property("FromTo") <- forAll { (p: TestProduct<Int,Int>) in
			let i1 = TestProduct<Int,Int>.iso.product
			let i2 = Couple<Int,Int>.iso.product.inverted
			let composed = i1..i2

			return IsoLaw.fromTo(whole: p, iso: composed)
		}

		property("ToFrom") <- forAll { (p: TestProduct<Int,Int>) in
            let i1 = TestProduct<Int,Int>.iso.product.inverted
            let i2 = Couple<Int,Int>.iso.product
            let composed = i2..i1
            
            return IsoLaw.toFrom(part: p, iso: composed)
		}
	}
}
