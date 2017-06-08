import XCTest
@testable import OpticsTests

XCTMain([
    testCase(LensTests.allTests),
    testCase(PrismTests.allTests)
])
