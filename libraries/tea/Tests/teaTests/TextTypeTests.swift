@testable import tea
import XCTest
import TermSwift

final class TextTypeTests: XCTestCase {
    
    func test_capping_when_not_too_long() {
        let t = Text("Not too long")
        let t2 = t.capTo(20)
        XCTAssertEqual(t.terminalRepresentation, t2.terminalRepresentation)
    }
    
    func test_capping_text_when_exactly_long_enough() {
        let t = Text("Exact size")
        let t2 = t.capTo(10)
        XCTAssertEqual(t.terminalRepresentation, t2.terminalRepresentation)
    }
    
    func test_capping_with_one_part_exact_length_second_part_removed() {
        let t = Text([(Formatting(.Default, .Default), "Exact size"), (Formatting(.Default, .Default), "Too long")])
        let t2 = t.capTo(10)
        let shouldBe = Text([(Formatting(.Default, .Default), "Exact size")])
        XCTAssertEqual(t2.terminalRepresentation, shouldBe.terminalRepresentation)
    }
    
    func test_capping_with_first_part_too_short_second_part_too_long() {
        let t = Text([(Formatting(.Default, .Default), "Exact size"), (Formatting(.Default, .Default), "Too long")])
        let t2 = t.capTo(12)
        let shouldBe = Text([(Formatting(.Default, .Default), "Exact size"), (Formatting(.Default, .Default), "To")])
        XCTAssertEqual(t2.terminalRepresentation, shouldBe.terminalRepresentation)
    }
    
    func test_capping_with_two_parts_fitting_third_too_long() {
        let t = Text([(Formatting(.Default, .Default), "First"), (Formatting(.Default, .Default), "Second"), (Formatting(.Default, .Default), "Third")])
        let t2 = t.capTo(15)
        let shouldBe = Text([(Formatting(.Default, .Default), "First"), (Formatting(.Default, .Default), "Second"), (Formatting(.Default, .Default), "Thir")])
        XCTAssertEqual(t2.terminalRepresentation, shouldBe.terminalRepresentation)
    }
}
