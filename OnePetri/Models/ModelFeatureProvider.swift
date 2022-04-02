//
//  ModelFeatureProvider.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-03.
//

import Foundation
import CoreML

class ModelFeatureProvider: MLFeatureProvider {
    // MARK: - Properties
    var iouThreshold: Double
    var confidenceThreshold: Double
    
    var featureNames: Set<String> {
        get {
            return ["iouThreshold", "confidenceThreshold"]
        }
    }
    
    // MARK: - Lifecycle
    init(iouThreshold: Double, confidenceThreshold: Double) {
        self.iouThreshold = iouThreshold
        self.confidenceThreshold = confidenceThreshold
    }
    
    // MARK: - Other Functions
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "iouThreshold") {
            return MLFeatureValue(double: iouThreshold)
        }
        if (featureName == "confidenceThreshold") {
            return MLFeatureValue(double: confidenceThreshold)
        }
        return nil
    }
    
}

