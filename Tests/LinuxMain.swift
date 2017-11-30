import XCTest
@testable import OpticsTests

XCTMain([
	testCase(AdapterTests.allTests),
	testCase(AffineTests.allTests),
    testCase(LensTests.allTests),
    testCase(PrismTests.allTests)
])
