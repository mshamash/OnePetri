//
//  OtherExtensions.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-09.
//

import UIKit
import MessageUI
import AVFoundation

extension UITextField {
    func addDoneButtonToKeyboard(dismissAction: Selector?) {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: dismissAction)
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
}

extension UIViewController: MFMailComposeViewControllerDelegate {
    func sendMail(imageMail: Bool, imageView: UIImageView? = nil, imageType: String? = nil) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self;
            mail.setToRecipients(["support@onepetri.ai"])
            mail.setMessageBody("Submitted using OnePetri, version \(appVersion)-\(appBuild)", isHTML: false)
            if imageMail {
                mail.setSubject("OnePetri Image Submission - \(imageType!)")
                let imageData = imageView!.image!.pngData()!
                mail.addAttachmentData(imageData, mimeType: "image/png", fileName: "image.png")
            } else {
                mail.setSubject("OnePetri Feedback")
            }
            present(mail, animated: true, completion: nil)
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension UIViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPicker(_ tag: Int) {
        if tag == 0 {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .overFullScreen
            present(picker, animated: true)
        } else if tag == 1 {
            if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                //already authorized
                let picker = UIImagePickerController()
                picker.delegate = self
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
                            let picker = UIImagePickerController()
                            picker.delegate = self
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
}

extension String {
    /// stringToFind must be at least 1 character.
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }
}
