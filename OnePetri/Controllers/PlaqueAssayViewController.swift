//
//  PlaqueAssayViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-09.
//

import UIKit

class PlaqueAssayViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var plateCountLabel: UILabel!
    @IBOutlet weak var plateStepper: UIStepper!
    @IBOutlet weak var volumeTextField: UITextField!
    
    @IBOutlet weak var dilutionSeriesTableView: UITableView!
    @IBOutlet weak var finalConcentrationLabel: UILabel!
    
    let assaySelection: Assay = .plaque
    var currentPlateID: Int?
    
    var plates = [Int: PetriDish]()
    var concentrations = [Int: String]()
    var meanConcentration = ""
    var volumePlated = 100.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        let resetIcon = UIImage(systemName: "trash", withConfiguration: largeConfig)
        resetButton.setImage(resetIcon, for: .normal)
        
        volumeTextField.addDoneButtonToKeyboard(dismissAction: #selector(volumeTextField.resignFirstResponder))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        calculateConcentration()
        dilutionSeriesTableView.reloadData()
    }
    
    @IBAction func plateValueChanged(_ sender: UIStepper) {
        //TODO: add code to delete plates that are hidden from tableview and recalculate average PFUs accordingly, as well as update [concentrations] dictionary
        
        let s = (sender.value == 1) ?  "" : "s"
        plateCountLabel.text = "\(Int(sender.value)) plate\(s)"
        
        dilutionSeriesTableView.reloadData()
    }

    @IBAction func resetButtonPressed(_ sender: UIButton) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSelectVC" {
            if let destination = segue.destination as? SelectImageViewController {
                destination.assaySelection = assaySelection
                destination.plaqueAssayViewConroller = self
                destination.assayPlateID = currentPlateID!
            }
        }
    }
    
    func calculateConcentration() {
        concentrations = [Int: String]()
        var tmpConcentrations = [Double]()
        for (key, value) in plates {
            let concentration = (Double(value.plaques.count) * (1000.0 / volumePlated) * NSDecimalNumber(decimal: pow(10, key)).doubleValue)
            tmpConcentrations.append(concentration)
            concentrations[key] = convertToSciNotation(value: concentration)
        }
        let tmpMeanConcentration = tmpConcentrations.reduce(0, +) / Double(tmpConcentrations.count)
        meanConcentration = convertToSciNotation(value: tmpMeanConcentration)
        
        if plates.count > 0 {
            finalConcentrationLabel.text = "Average concentration: \(meanConcentration) PFU/mL"
        } else {
            finalConcentrationLabel.text = "Add plates to the assay to continue."
        }
    }
    
    func convertToSciNotation(value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.positiveFormat = "0.###E+0"
        formatter.exponentSymbol = "e"
        if let scientificFormatted = formatter.string(for: value) {
            return scientificFormatted
        }
        
        return ""
    }
    
}

extension PlaqueAssayViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(plateStepper.value)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaqueAssayCell", for: indexPath) as! PlaqueAssayTableViewCell
        
        cell.plateLabel.text = "Plate \(indexPath.row + 1)"
        
        let font:UIFont? = UIFont.systemFont(ofSize: 17)
        let fontSuper:UIFont? = UIFont.systemFont(ofSize: 12)
        let baseString = "Dilution factor: 10-"
        let attString:NSMutableAttributedString = NSMutableAttributedString(string: "\(baseString)\(indexPath.row + 1)", attributes: [.font: font!])
        let expLength = indexPath.row + 1 <= 9 ? 2 : 3
        attString.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: baseString.count - 1,length: expLength))
        cell.dilutionFactorLabel.attributedText = attString
        
        let isKeyValid = plates[indexPath.row+1] != nil
        
        if isKeyValid {
            let petriDish = plates[indexPath.row+1]
            cell.petriDish = petriDish
            
           
            
//            let concentration = (Double(petriDish!.plaques.count) * (1000.0 / volumePlated) * NSDecimalNumber(decimal: pow(10, indexPath.row+1)).doubleValue)
////            let roundedConcentration = String(format: "%.2f", concentration)
            
//            let formatter = NumberFormatter()
//            formatter.numberStyle = .scientific
//            formatter.positiveFormat = "0.###E+0"
//            formatter.exponentSymbol = "e"
//            if let scientificFormatted = formatter.string(for: concentration) {
//                let s = (petriDish!.plaques.count == 1) ?  "" : "s"
//                cell.concentrationLabel.text = "\(scientificFormatted) PFU/mL (\(petriDish!.plaques.count) plaque\(s))"
//            }
            
            let s = (petriDish!.plaques.count == 1) ?  "" : "s"
            cell.concentrationLabel.text = "\(concentrations[indexPath.row+1]!) PFU/mL (\(petriDish!.plaques.count) plaque\(s))"
            
//            let s = (petriDish!.plaques.count == 1) ?  "" : "s"
//            cell.concentrationLabel.text = "\(roundedConcentration) PFU/mL (\(petriDish!.plaques.count) plaque\(s))"
            cell.petriImageView.image = petriDish!.croppedPetriImg
        } else {
            cell.petriDish = nil
            cell.concentrationLabel.text =  "No plate selected"
            cell.petriImageView.image =  nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentPlateID = indexPath.row + 1
        self.performSegue(withIdentifier: "toSelectVC", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
}

extension PlaqueAssayViewController: UITextViewDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let volume = textField.text, !volume.isEmpty { volumePlated = Double(volume)! } else { volumePlated = 100.0 }
        calculateConcentration()
        dilutionSeriesTableView.reloadData()
    }
}

class PlaqueAssayTableViewCell: UITableViewCell {
    @IBOutlet weak var plateLabel: UILabel!
    @IBOutlet weak var dilutionFactorLabel: UILabel!
    @IBOutlet weak var concentrationLabel: UILabel!
    @IBOutlet weak var petriImageView: UIImageView!
    
    var petriDish: PetriDish!
}
