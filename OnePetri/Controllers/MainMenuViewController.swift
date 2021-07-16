//
//  MainMenuViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-08.
//

import UIKit
import AVFoundation

enum Assay { case quick, plaque, adsorption, eop }

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
let petriDishModelVersion = "1.0"
let plaqueModelVersion = "1.0"

class MainMenuViewController: UIViewController {
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!

    var image: UIImage?
    var assaySelection: Assay?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appVersionLabel.text = "Version \(appVersion)-\(appBuild)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func selectPhotoPressed(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if sender.tag == 0 {
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .overFullScreen
            present(picker, animated: true)
        } else if sender.tag == 1 {
            if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                //already authorized
                picker.sourceType = .camera
                picker.modalPresentationStyle = .overFullScreen
                present(picker, animated: true)
                print("auth")
            } else {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                    if granted {
                        //access allowed
                        print("granted")
                        DispatchQueue.main.async {
                            picker.sourceType = .camera
                            picker.modalPresentationStyle = .overFullScreen
                            self.present(picker, animated: true)
                        }
                    } else {
                        //access denied
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Camera access disabled", message: "It looks like camera access for OnePetri has been disabled. Please enable access in iOS Settings if you wish to use the camera to take photos for analysis within OnePetri.", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        
                        self.present(alert, animated: true)
                        }
                    }
                })
            }
        }
        
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
    
}

extension MainMenuViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        image = selectedImage
        assaySelection = .quick // Quick count
        
        performSegue(withIdentifier: "toSelectVC", sender: "quickCount")
    }
}


extension UINavigationController {
  func popToViewController(ofClass: AnyClass, animated: Bool = true) {
    if let vc = viewControllers.filter({$0.isKind(of: ofClass)}).last {
      popToViewController(vc, animated: animated)
    }
  }
}
