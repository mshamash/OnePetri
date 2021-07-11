//
//  SettingsViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-08.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var petriConfTextField: UITextField!
    @IBOutlet weak var petriIOUTextField: UITextField!
    @IBOutlet weak var plaqueConfTextField: UITextField!
    @IBOutlet weak var plaqueIOUTextField: UITextField!
    @IBOutlet weak var plaqueNMSIOUTextField: UITextField!
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var petriModelVersionLabel: UILabel!
    @IBOutlet weak var plaqueModelVersionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        petriConfTextField.addDoneButtonToKeyboard(dismissAction: #selector(petriConfTextField.resignFirstResponder))
        petriIOUTextField.addDoneButtonToKeyboard(dismissAction: #selector(petriIOUTextField.resignFirstResponder))
        plaqueConfTextField.addDoneButtonToKeyboard(dismissAction: #selector(plaqueConfTextField.resignFirstResponder))
        plaqueIOUTextField.addDoneButtonToKeyboard(dismissAction: #selector(plaqueIOUTextField.resignFirstResponder))
        plaqueNMSIOUTextField.addDoneButtonToKeyboard(dismissAction: #selector(plaqueNMSIOUTextField.resignFirstResponder))
        
        appVersionLabel.text = "OnePetri version \(appVersion)-\(appBuild)"
        petriModelVersionLabel.text = "Petri dish model version \(petriDishModelVersion)"
        plaqueModelVersionLabel.text = "Plaque model version \(plaqueModelVersion)"
    }

}
