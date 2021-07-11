//
//  Plaque.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-02.
//

import Foundation
import CoreGraphics
import QuartzCore

class Plaque {
    let petriDish: PetriDish
//    let locInTile: CGRect
    var locInLayer: CGRect
    let plaqueLayer: CALayer
    
    init(petriDish: PetriDish, /*locInTile: CGRect,*/ locInLayer: CGRect, plaqueLayer: CALayer) {
        self.petriDish = petriDish
//        self.locInTile = locInTile
        self.locInLayer = locInLayer
        self.plaqueLayer = plaqueLayer
    }
}
