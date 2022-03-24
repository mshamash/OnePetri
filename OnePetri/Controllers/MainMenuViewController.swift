//
//  MainMenuViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-08.
//

import UIKit
import SafariServices

enum Assay { case quick, plaque, adsorption, eop }

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
let petriDishModelVersion = "1.1"
let plaqueModelVersion = "1.1"

class MainMenuViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!

    var image: UIImage?
    var assaySelection: Assay?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appVersionLabel.text = "Version \(appVersion)-\(appBuild)"
        
        #if DEBUG
        appVersionLabel.text = "Version \(appVersion)-\(appBuild)+DEBUG"
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSelectVC" {
            if let destination = segue.destination as? SelectImageViewController {
                destination.assaySelection = assaySelection
                if let image = image, sender as? String == "quickCount" {
                    destination.petriDishImage = image
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func selectPhotoPressed(_ sender: UIButton) {
        presentPicker(sender.tag)        
    }
    
    @IBAction func didChooseAssay(_ sender: UIButton) {
        if sender.tag == 1 {
            assaySelection = .plaque // Plaque assay
            self.performSegue(withIdentifier: "toPlaqueAssayVC", sender: self)
        } else if sender.tag == 2 {
            assaySelection = .adsorption // Adsorption assay
            self.performSegue(withIdentifier: "toSelectVC", sender: self)
        } else if sender.tag == 3 {
            assaySelection = .eop // EOP assay
            self.performSegue(withIdentifier: "toSelectVC", sender: self)
        }
    }
    
    @IBAction func didTapSettings(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toSettingsVC", sender: self)
    }
    
    @IBAction func didTapTips(_ sender: UIButton) {
        let svc = SFSafariViewController(url: URL(string:"https://onepetri.ai/tips/")!)
        svc.dismissButtonStyle = .close
        self.present(svc, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainMenuViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            image = selectedImage
            assaySelection = .quick // Quick count
            
            performSegue(withIdentifier: "toSelectVC", sender: "quickCount")
        } else {
            let alert = UIAlertController(title: "Invalid selection", message: "An invalid image was selected, please try again.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
}

