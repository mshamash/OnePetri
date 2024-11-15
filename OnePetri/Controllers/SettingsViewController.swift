//
//  SettingsViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-08.
//

import UIKit
import SafariServices

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var petriConfTextField: UITextField!
    @IBOutlet weak var petriIOUTextField: UITextField!
    @IBOutlet weak var plaqueConfTextField: UITextField!
    @IBOutlet weak var plaqueIOUTextField: UITextField!
//    @IBOutlet weak var plaqueNMSIOUTextField: UITextField!
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var petriModelVersionLabel: UILabel!
    @IBOutlet weak var plaqueModelVersionLabel: UILabel!
    
    private var defaults: UserDefaults!
    private var endEditing: Bool!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaults = UserDefaults.standard
        
        let petriConfThreshold = defaults.double(forKey: "PetriConfThreshold")
        let petriIOUThreshold = defaults.double(forKey: "PetriIOUThreshold")
        let plaqueConfThreshold = defaults.double(forKey: "PlaqueConfThreshold")
        let plaqueIOUThreshold = defaults.double(forKey: "PlaqueIOUThreshold")
//        let plaqueNMSIOUThreshold = defaults.double(forKey: "PlaqueNMSIOUThreshold")
        
        petriConfTextField.text = (petriConfThreshold != 0.0 ? "\(petriConfThreshold)" : "")
        petriIOUTextField.text = (petriIOUThreshold != 0.0 ? "\(petriIOUThreshold)" : "")
        plaqueConfTextField.text = (plaqueConfThreshold != 0.0 ? "\(plaqueConfThreshold)" : "")
        plaqueIOUTextField.text = (plaqueIOUThreshold != 0.0 ? "\(plaqueIOUThreshold)" : "")
//        plaqueNMSIOUTextField.text = (plaqueNMSIOUThreshold != 0.0 ? "\(plaqueNMSIOUThreshold)" : "")
        
        petriConfTextField.addDoneButtonToKeyboard(dismissAction: #selector(petriConfTextField.resignFirstResponder))
        petriIOUTextField.addDoneButtonToKeyboard(dismissAction: #selector(petriIOUTextField.resignFirstResponder))
        plaqueConfTextField.addDoneButtonToKeyboard(dismissAction: #selector(plaqueConfTextField.resignFirstResponder))
        plaqueIOUTextField.addDoneButtonToKeyboard(dismissAction: #selector(plaqueIOUTextField.resignFirstResponder))
//        plaqueNMSIOUTextField.addDoneButtonToKeyboard(dismissAction: #selector(plaqueNMSIOUTextField.resignFirstResponder))
        
        appVersionLabel.text = "OnePetri version \(appVersion)-\(appBuild)"
        petriModelVersionLabel.text = "Petri dish model version \(petriDishModelVersion)"
        plaqueModelVersionLabel.text = "Plaque model version \(plaqueModelVersion)"
    }
    
    // MARK: - Actions
    @IBAction func didTapInfo(_ sender: UIBarButtonItem) {        
        let svc = SFSafariViewController(url: URL(string:"https://onepetri.shamash.me/technology/")!)
        svc.dismissButtonStyle = .close
        self.present(svc, animated: true, completion: nil)
    }

}

// MARK: - UITextFieldDelegate
extension SettingsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if endEditing {
            if textField.tag == 0 {
                if let value = textField.text, !value.isEmpty { defaults.set(Double(value), forKey: "PetriConfThreshold") } else { defaults.removeObject(forKey: "PetriConfThreshold") }
            } else if textField.tag == 1 {
                if let value = textField.text, !value.isEmpty { defaults.set(Double(value), forKey: "PetriIOUThreshold") } else { defaults.removeObject(forKey: "PetriIOUThreshold") }
            } else if textField.tag == 2 {
                if let value = textField.text, !value.isEmpty { defaults.set(Double(value), forKey: "PlaqueConfThreshold") } else { defaults.removeObject(forKey: "PlaqueConfThreshold") }
            } else if textField.tag == 3 {
                if let value = textField.text, !value.isEmpty { defaults.set(Double(value), forKey: "PlaqueIOUThreshold") } else { defaults.removeObject(forKey: "PlaqueIOUThreshold") }
            } /*else if textField.tag == 4 {
                if let value = textField.text, !value.isEmpty { defaults.set(Double(value), forKey: "PlaqueNMSIOUThreshold") } else { defaults.removeObject(forKey: "PlaqueNMSIOUThreshold") }
            }*/
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        endEditing = true
        
        if let value = textField.text, !value.isEmpty {
            if value.countInstances(of: ".") != 1 { endEditing = false }
            
            if value == "." { endEditing = false }
            
            let doubleVal = Double(value)
            if doubleVal == 0.0 || doubleVal == 1.0 { endEditing = false }
        }
        
        if !endEditing {
            let alert = UIAlertController(title: "Invalid threshold", message: "The value entered should be between 0.00 and 1.00 (exclusively), or left empty to use the default value.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
        
        return true
    }
}
