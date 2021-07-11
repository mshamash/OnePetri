//
//  OtherExtensions.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-09.
//

import UIKit
import MessageUI


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
    func sendMail(imageView: UIImageView, imageType: String) {
      if MFMailComposeViewController.canSendMail() {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self;
        mail.setToRecipients(["michael@onepetri.ai"])
        mail.setSubject("Image submission - \(imageType)")
        mail.setMessageBody("Submitted using OnePetri, version \(appVersion)-\(appBuild)", isHTML: false)
        let imageData = imageView.image!.pngData()!
        mail.addAttachmentData(imageData, mimeType: "image/png", fileName: "image.png")
        present(mail, animated: true, completion: nil)
      }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
