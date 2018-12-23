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

    func testEx3() {
        XCTAssertEqual(demangle(name: "$S13ExampleAnimal3DogV4barkSSyF"),
                       "ExampleAnimal.Dog.bark() -> Swift.String")
    }

    func testEx4() {
        XCTAssertEqual(demangle(name: "$S13ExampleSquare6square6numberS2i_tF"),
                       "ExampleSquare.square(number: Swift.Int) -> Swift.Int")

        XCTAssertEqual(demangle(name: "$S13ExampleNumber6square1a1b1c1d1e1f1g1h1i1j1k1l1m1nS2i_S13itF"),
                       "ExampleNumber.square(a: Swift.Int, b: Swift.Int, c: Swift.Int, d: Swift.Int, e: Swift.Int, f: Swift.Int, g: Swift.Int, h: Swift.Int, i: Swift.Int, j: Swift.Int, k: Swift.Int, l: Swift.Int, m: Swift.Int, n: Swift.Int) -> Swift.Int")
    }

    static var allTests = [
        ("testEx1", testEx1),
    ]
}
