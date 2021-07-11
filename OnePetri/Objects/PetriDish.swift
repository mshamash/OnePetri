//
//  PetriDish.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-06-30.
//

import Foundation
import CoreGraphics
import UIKit


class PetriDish {
    var locInView: CGRect
    var locInImg: CGRect
    var croppedPetriImg: UIImage!
    var plaques: [Plaque] = [Plaque]()
    
    init(locInView: CGRect, locInImg: CGRect, croppedPetriImg: UIImage) {
        self.locInView = locInView
        self.locInImg = locInImg
        self.croppedPetriImg = croppedPetriImg
    }
}
