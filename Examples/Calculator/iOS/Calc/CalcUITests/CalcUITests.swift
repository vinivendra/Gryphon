import XCTest

class CalcUITests: XCTestCase {
    let app = XCUIApplication()
    
    
    // MARK: - Setup and Teardown
        
    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // MARK: - Addition
    
    /**
        Performs a chained addition test. The test has two parts: 
        1. Enter in the calculator and check: 6 + 2 = 8.
        2. Check: display value + 2 = 10.
    */
    func testAddition() {
        app.buttons["6"].tap()
        app.buttons["+"].tap()
        app.buttons["2"].tap()
        app.buttons["="].tap()
        
        // Check whether the display textfield shows 8.
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "8.0", "Part 1 failed.")
        }
        
        app.buttons["+"].tap()
        app.buttons["2"].tap()
        app.buttons["="].tap()
        
        // Check whether the display textfield shows 10.
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "10.0", "Part 2 failed.")
        }
    }
    
    
    // MARK: - Subtraction
    
    /// Performs a substraction test. Enter in the calculator and check: 6 - 2 = 4.
    func testSubtraction() {
        app.buttons["6"].tap()
        app.buttons["-"].tap()
        app.buttons["2"].tap()
        app.buttons["="].tap()
        
        // Check that whether the display textfield shows 4.
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "4.0", "Incorrect value.")
        }
    }
    
    
    // MARK: - Division
    
    /// Performs a division test. Enter in the calculator and check: 25 / 4 = 6.25.
    func testDivision() {
        app.buttons["2"].tap()
        app.buttons["5"].tap()
        app.buttons["/"].tap()
        app.buttons["4"].tap()
        app.buttons["="].tap()
        
        // Check whether the display textfield shows 6.25.
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "6.25", "Incorrect value.")
        }
    }
    
    
    // MARK: - Multiplication
    
    /// Performs a multiplication test. Enter in the calculator and check: 19 x 8 = 152.
    func testMultiplication() {
        app.buttons["1"].tap()
        app.buttons["9"].tap()
        app.buttons["*"].tap()
        app.buttons["8"].tap()
        app.buttons["="].tap()
        
        // Check whether the display textfield shows 152.
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "152.0", "Incorrect value.")
        }
    }
    
    
    // MARK: - Delete
    /**
        Tests the functionality of the D (Delete) key. 
        1. Enter the number 1987 into the calculator.
        2. Delete each digit, and test the display to ensure
           the correct display contains the expected value after each D tap.
    */
    func testDelete() {
        app.buttons["1"].tap()
        app.buttons["9"].tap()
        app.buttons["8"].tap()
        app.buttons["7"].tap()
        app.buttons["="].tap()
        
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "1987", "Part 1 failed.")
        }
        
        app.buttons["D"].tap()
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "198", "Part 2 failed.")
        }
        
        app.buttons["D"].tap()
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "19", "Part 3 failed.")
        }
        
        app.buttons["D"].tap()
        
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "1", "Part 4 failed.")
        }
        
        app.buttons["D"].tap()
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "0", "Part 5 failed.")
        }
    }
    
    
    // MARK: - Clear
    
    /**
        Tests the functionality of the C (Clear) key.
        1. Clear the display.
            - Enter the calculation 25 / 4.
            - Tap C.
            - Ensure the display contains the value 0.
        2. Perform corrected computation.
            - Tap 5, =.
            - Ensure the display contains the value 5.
        3. Ensure tapping C twice clears all.
            - Enter the calculation 19 x 8.
            - Tap C (clears the display).
            - Tap C (clears the operand).
            - Tap +, 2, =.
       		- Ensure the display contains the value 2.
    */
    func testClear() {
        app.buttons["2"].tap()
        app.buttons["5"].tap()
        app.buttons["/"].tap()
        app.buttons["4"].tap()
        app.buttons["="].tap()
        app.buttons["C"].tap()
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "0", "Part 1 failed.")
        }
        
        app.buttons["5"].tap()
        app.buttons["="].tap()
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "5", "Part 2 failed.")
        }
        
        app.buttons["1"].tap()
        app.buttons["9"].tap()
        app.buttons["*"].tap()
        app.buttons["8"].tap()
        app.buttons["C"].tap()
        app.buttons["C"].tap()
        app.buttons["+"].tap()
        app.buttons["2"].tap()
        app.buttons["="].tap()
        if let textFieldValue = app.textFields["display"].value as? String {
            XCTAssertTrue(textFieldValue == "2.0", "Part 3 failed.")
        }
    }
}
