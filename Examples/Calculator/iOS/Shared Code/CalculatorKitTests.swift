import XCTest
@testable import CalculatorKit

class CalculatorKitTests: XCTestCase {
    // MARK: - Properties
    
    var calculator: Calculator?
    
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        calculator = Calculator()
        XCTAssertNotNil(calculator, "Cannot create Calculator instance.")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Addition
    
    /// Performs a simple addition test: 6 + 2 = 8.
    func testAddition() {
        if let calculator = calculator {
            
            try? calculator.input("6")
            try? calculator.input("+")
            try? calculator.input("2")
            try? calculator.input("=")
            XCTAssertTrue(calculator.displayValue == "8.0")
        }
    }
    
    
    // MARK: - Subtraction
    
    /// Performs a simple subtraction test: 19 - 2 = 17.
    func testSubtraction() {
        if let calculator = calculator {
            
            try? calculator.input("1")
            try? calculator.input("9")
            try? calculator.input("-")
            try? calculator.input("2")
            try? calculator.input("=")
            XCTAssertTrue(calculator.displayValue == "17.0")
        }
    }
    
    
    // MARK: - Division
    
    /// Performs a simple division test: 19 / 8 = 2.375.
    func testDivision() {
        if let calculator = calculator {
            
            try? calculator.input("1")
            try? calculator.input("9")
            try? calculator.input("/")
            try? calculator.input("8")
            try? calculator.input("=")
            XCTAssertTrue(calculator.displayValue == "2.375")
        }
    }
    
    // MARK: - Multiplication
    
    /// Performs a simple multiplication test: 6 * 2 = 12.
    func testMultiplication() {
        if let calculator = calculator {
            
            try? calculator.input("6")
            try? calculator.input("*")
            try? calculator.input("2")
            try? calculator.input("=")
            XCTAssertTrue(calculator.displayValue == "12.0")
        }
    }
    
    
    // MARK: - Subtraction Negative Result
    
    /// Performs a simple subtraction test with a negative result: 6 - 24 = -18.
    func testSubtractionNegativeResult() {
        if let calculator = calculator {
            
            try? calculator.input("6")
            try? calculator.input("-")
            try? calculator.input("2")
            try? calculator.input("4")
            try? calculator.input("=")
            XCTAssertTrue(calculator.displayValue == "-18.0")
        }
    }
    
    
    // MARK: - Clear Last Entry
    
    /// Tests that the clear (C) key clears the last entry when used once.
    func testClearLastEntry() {
        if let calculator = calculator {
            
            try? calculator.input("7")
            try? calculator.input("+")
            try? calculator.input("3")
            try? calculator.input("C")
            try? calculator.input("4")
            try? calculator.input("=")
            XCTAssertTrue(calculator.displayValue == "11.0")
        }
    }
    
    
    // MARK: - Clear Computation
    
    /// Tests that the clear (C) key clears the computation when used twice.
    func testClearComputation() {
        if let calculator = calculator {
            
            try? calculator.input("C")
            try? calculator.input("7")
            try? calculator.input("+")
            try? calculator.input("3")
            try? calculator.input("C")
            try? calculator.input("C")
            XCTAssertTrue(calculator.displayValue == "0")
        }
    }
    
    
    // MARK: - Input Exception
    
    /**
        Tests that the input: method throws an exception in three situations:
        1. The argument contains more than one character.
        2. The argument contains an invalid character.
        3. The argument is nil.
    */
    func testInputException() {
        if let calculator = calculator {
            
            XCTAssertThrowsError(try calculator.input("67")) { error in
                print(error.localizedDescription)
            }
            
            XCTAssertThrowsError(try calculator.input("j")) { error in
                print(error.localizedDescription)
            }
            
            XCTAssertThrowsError(try calculator.input(nil)) { error in
                print(error.localizedDescription)
            }
        }
    }
}
