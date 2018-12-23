//
//  ParserTests.swift
//  SwiftDemanglerTests
//
//  Created by ukitaka on 2018/12/16.
//

import XCTest
@testable import SwiftDemangler

class ParserTests: XCTestCase {
    func testParseInt() {

        // 0
        var parser = Parser(name: "0")
        XCTAssertEqual(parser.parseInt(), 0)
        XCTAssertEqual(parser.remainsString, "")
        
        // 1
        parser = Parser(name: "1")
        XCTAssertEqual(parser.parseInt(), 1)
        XCTAssertEqual(parser.remainsString, "")
        
        // 12
        parser = Parser(name: "12")
        XCTAssertEqual(parser.parseInt(), 12)
        XCTAssertEqual(parser.remainsString, "")
        
        // 12
        parser = Parser(name: "12A")
        XCTAssertEqual(parser.parseInt(), 12)
        XCTAssertEqual(parser.remainsString, "A")
        
        // 1
        parser = Parser(name: "1B2A")
        XCTAssertEqual(parser.parseInt(), 1)
        XCTAssertEqual(parser.remainsString, "B2A")
        XCTAssertEqual(parser.parseInt(), nil)
    }

    func testParseIdentifierWithLength() {
        let parser = Parser(name: "3ABC4DEFG")

        XCTAssertEqual(parser.parseInt(), 3)
        XCTAssertEqual(parser.remainsString, "ABC4DEFG")
        XCTAssertEqual(parser.parseIdentifier(length: 3), "ABC")
        XCTAssertEqual(parser.remainsString, "4DEFG")

        XCTAssertEqual(parser.parseInt(), 4)
        XCTAssertEqual(parser.remainsString, "DEFG")
        XCTAssertEqual(parser.parseIdentifier(length: 4), "DEFG")
    }

    func testParseIdentifier() {
        let parser = Parser(name: "3ABC4DEFG")

        XCTAssertEqual(parser.parseIdentifier(), "ABC")
        XCTAssertEqual(parser.remainsString, "4DEFG")

        XCTAssertEqual(parser.parseIdentifier(), "DEFG")
    }

    func testModule() {
        let parser = Parser(name: "$S13ExampleNumber6isEven6numberSbSi_tF")
        let _ = parser.parsePrefix()
        XCTAssertEqual(parser.parseModule(), "ExampleNumber")
    }

    func testDeclName() {
        let parser = Parser(name: "$S13ExampleNumber6isEven6numberSbSi_tF")
        let _ = parser.parsePrefix()
        let _ = parser.parseModule()
        XCTAssertEqual(parser.parseDeclName(), "isEven")
    }

    func testLabelList() {
        let parser = Parser(name: "$S13ExampleNumber6isEven6numberSbSi_tF")
        let _ = parser.parsePrefix()
        let _ = parser.parseModule()
        let _ = parser.parseDeclName()
        XCTAssertEqual(parser.parseLabelList(), ["number"])
    }

    func testParseKnownType() {
        XCTAssertEqual(Parser(name: "Si").parseKnownType(), .int)
        XCTAssertEqual(Parser(name: "Sb").parseKnownType(), .bool)
        XCTAssertEqual(Parser(name: "SS").parseKnownType(), .string)
        XCTAssertEqual(Parser(name: "Sf").parseKnownType(), .float)
        XCTAssertEqual(Parser(name: "y").parseKnownType(), .void)
        XCTAssertEqual(Parser(name: "Sf_SfSft").parseType(), .list([.float, .float, .float]))
    }

    func testParseFunctionSignature() {
        XCTAssertEqual(Parser(name: "SbSi_t").parseFunctionSignature(),
                       FunctionSignature(returnType: .bool, argsType: .list([.int])))
    }

    func testParseFunctionEntity() {
        let sig = FunctionSignature(returnType: .bool, argsType: .list([.int]))
        XCTAssertEqual(Parser(name: "13ExampleNumber6isEven6numberSbSi_tF").parseFunctionEntity(),
                       FunctionEntity(module: "ExampleNumber", nominalType: nil, declName: "isEven", labelList: ["number"], functionSignature: sig, throws: false))
    }

    func testParseNominalType() {
        XCTAssertEqual(Parser(name: "3DogV").parseNominalType(),
                       NominalTypeHolder(type: .struct, name: "Dog"))
        XCTAssertEqual(Parser(name: "3Dog").parseNominalType(),
                       nil)
    }
}
