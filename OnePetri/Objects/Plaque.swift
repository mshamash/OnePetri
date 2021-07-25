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
    
    // MARK: - Properties
    weak var petriDish: PetriDish?
    var locInLayer: CGRect
    let plaqueLayer: CALayer
    
    // MARK: - Lifecycle
    init(petriDish: PetriDish, locInLayer: CGRect, plaqueLayer: CALayer) {
        self.petriDish = petriDish
        self.locInLayer = locInLayer
        self.plaqueLayer = plaqueLayer
    }
}
