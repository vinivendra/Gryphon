import UIKit
@testable import CalculatorKit

class CalcViewController: UIViewController {
    // MARK: - Properties
    
    var calculator = Calculator()
    @IBOutlet weak var display: UITextField!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - Handle Tapped Character
    
    @IBAction func tap(_ sender: UIButton) {
        if let label = sender.titleLabel?.text {
            
            do {
                try calculator.input(label)
                display.text = calculator.displayValue
            } catch let error {
                print("\(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
