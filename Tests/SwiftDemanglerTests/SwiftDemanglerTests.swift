import XCTest
@testable import SwiftDemangler

final class SwiftDemanglerTests: XCTestCase {
    func testEx1() {
        XCTAssertEqual(demangle(name: "$S13ExampleNumber6isEven6numberSbSi_tF"),
                       "ExampleNumber.isEven(number: Swift.Int) -> Swift.Bool")
    }

    func testEx2_MultiArgs() {
        XCTAssertEqual(demangle(name: "$S13ExampleNumber6isEven6number4hoge4fugaSbSi_SSSftF"),
                       "ExampleNumber.isEven(number: Swift.Int, hoge: Swift.String, fuga: Swift.Float) -> Swift.Bool")
    }

    func testEx2_throws() {
        XCTAssertEqual(demangle(name: "$S13ExampleNumber6isEven6numberSbSi_tKF"),
                       "ExampleNumber.isEven(number: Swift.Int) throws -> Swift.Bool")
    }

    func testEx2_void() {
        XCTAssertEqual(demangle(name: "$S13ExampleNumber6isEvenSbyF"),
                       "ExampleNumber.isEven() -> Swift.Bool")

        XCTAssertEqual(demangle(name: "$S13ExampleNumber6isEven6numberySi_tF"),
                       "ExampleNumber.isEven(number: Swift.Int) -> ()")

        XCTAssertEqual(demangle(name: "$S13ExampleNumber6isEvenyyF"),
                       "ExampleNumber.isEven() -> ()")
    }

    static var allTests = [
        ("testEx1", testEx1),
    ]
}
