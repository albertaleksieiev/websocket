#if os(Linux) || os(Android)

import XCTest
@testable import WebSocketTests

XCTMain([
    testCase(WebSocketTests.allTests),
])

#endif
