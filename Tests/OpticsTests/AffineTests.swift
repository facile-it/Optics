import XCTest
import SwiftCheck
@testable import Optics

class AffineTests: XCTestCase {
	func testArrayAffineWellBehaved() {
		property("TrySetTryGet") <- forAll { (aa: ArrayOf<Int>, v: Int, i: UInt) in
			let array = aa.getArray
			let affine = type(of: array).affine(at: Int(i))
			return AffineLaw.trySetTryGet(affine: affine, whole: array, part: v)
		}

		property("TryGetTrySet") <- forAll { (aa: ArrayOf<Int>, i: UInt) in
			let array = aa.getArray
			let affine = type(of: array).affine(at: Int(i))
			return AffineLaw.tryGetTrySet(affine: affine, whole: array)
		}

		property("TrySetTrySet") <- forAll { (aa: ArrayOf<Int>, v: Int, i: UInt) in
			let array = aa.getArray
			let affine = type(of: array).affine(at: Int(i))
			return AffineLaw.trySetTrySet(affine: affine, whole: array, part: v)
		}
	}


}
