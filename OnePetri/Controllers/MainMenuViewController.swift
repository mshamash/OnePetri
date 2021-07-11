//
//  MainMenuViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-08.
//

import UIKit

enum Assay { case quick, plaque, adsorption, eop }

class MainMenuViewController: UIViewController {
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!

    var image: UIImage?
    var assaySelection: Assay?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        let largeGear = UIImage(systemName: "gearshape", withConfiguration: largeConfig)
        let largePhoto = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: largeConfig)
        let largeCamera = UIImage(systemName: "camera.fill", withConfiguration: largeConfig)
        settingsButton.setImage(largeGear, for: .normal)
        photoLibraryButton.setImage(largePhoto, for: .normal)
        cameraButton.setImage(largeCamera, for: .normal)
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
        } else if sender.tag == 1 {
            picker.sourceType = .camera
        }
        picker.modalPresentationStyle = .overFullScreen
        present(picker, animated: true)
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