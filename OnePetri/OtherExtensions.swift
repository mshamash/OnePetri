//
//  OtherExtensions.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-09.
//

import UIKit


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