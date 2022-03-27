//
//  SelectImageViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-06-20.
//

import UIKit
import Vision

class SelectImageViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var starterLabel: UILabel!
    
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    
    var plaqueAssayViewConroller: PlaqueAssayViewController?
    var assayPlateID: Int?
    
    var petriDishImage: UIImage?
    var assaySelection: Assay!
    
    private var detectionOverlay: CALayer! = nil
    private var petriDetections = [PetriDish]()
    private var imgToProcess: UIImage!
    private var petriToProcess: PetriDish!
    
    // Vision parts
    private var requests = [VNRequest]()
    private let modelImgSize: CGFloat = 640.0
    private var confThreshold: Double!
    private var iouThreshold: Double!
    
    struct Prediction {
        let labelIndex: Int
        let confidence: Float
        let boundingBox: CGRect
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        let petriConfThreshold = defaults.double(forKey: "PetriConfThreshold")
        let petriIOUThreshold = defaults.double(forKey: "PetriIOUThreshold")
        confThreshold = (petriConfThreshold != 0.0 ? petriConfThreshold : 0.50)
        iouThreshold = (petriIOUThreshold != 0.0 ? petriIOUThreshold : 0.10)
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        print("Assay selection is:", assaySelection!)
        
        if let petriDishImage = petriDishImage, assaySelection == .quick {
            detectionOverlay.sublayers = nil
            imageView.image = petriDishImage
            
            starterLabel.isHidden = true
            textView.isHidden = false
            helpButton.isHidden = false
            
            updateLayerGeometry()
            classifyImage(petriDishImage)
        } else {
            starterLabel.isHidden = false
            textView.isHidden = true
            helpButton.isHidden = true
        }
        
  }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCountVC" {
            if let destination = segue.destination as? CountPlaquesViewController {
                destination.origPetriDishImage = petriDishImage
                destination.petriDishImage = imgToProcess
                destination.petriDish = petriToProcess
                destination.assaySelection = assaySelection
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func didTapHelp(_ sender: UIButton) {
        let alert = UIAlertController(title: "Missing Petri dish?", message: "If a Petri dish was not detected, you may submit the selected image to help improve future iterations of OnePetri's AI models. Would you like to submit this image for analysis?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Send Image", style: .default, handler: { _ in
            self.sendMail(imageMail: true, image: self.petriDishImage, imageType: "Petri dish")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = helpButton
        
        self.present(alert, animated: true)
    }
  
    @IBAction func selectPhotoPressed(_ sender: UIButton) {
        presentPicker(sender.tag)
    }
    
    // MARK: - Vision Functions
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "Yv5-petri-res640_epochs500_v4-yv5n_v61", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { [weak self] (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self?.drawVisionRequestResults(results)
                    }
                })
            })
            objectRecognition.imageCropAndScaleOption = .scaleFill
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        petriDetections = [PetriDish]()
        
        let objectObservation = results as! [VNCoreMLFeatureValueObservation]

        let outputArray: [Float] = try! Array(UnsafeBufferPointer<Float>(objectObservation[3].featureValue.multiArrayValue!))
        let rows = objectObservation[3].featureValue.multiArrayValue!.shape[1].intValue
        let valPerRow = objectObservation[3].featureValue.multiArrayValue!.shape[2].intValue
        
        var unorderedPredictions = [Prediction]()
    
        for i in 0..<rows {
            let confidence = outputArray[(i * valPerRow) + 4]
            if(confidence > Float(confThreshold)){
                 let row = Array(outputArray[(i * valPerRow)..<(i + 1) * valPerRow])
                 let classes = Array(row.dropFirst(5))
                 let classIndex : Int = classes.firstIndex(of: classes.max() ?? 0) ?? 0
                    let detection: [Float] = [row[0] - row[2]/2, row[1] - row[3]/2, row[2], row[3], confidence, Float(classIndex)]
                
                
                let bb = CGRect(x: Double(detection[0]), y: Double(detection[1]), width: Double(detection[2]), height: Double(detection[3]))
                
                let prediction = Prediction(labelIndex: classIndex,
                                                    confidence: confidence,
                                                    boundingBox: bb)
                unorderedPredictions.append(prediction)
               }
            }
        
        var predictions: [Prediction] = []
        let orderedPredictions = unorderedPredictions.sorted { $0.confidence > $1.confidence }
        var keep = [Bool](repeating: true, count: orderedPredictions.count)
        for i in 0..<orderedPredictions.count {
            if keep[i] {
                predictions.append(orderedPredictions[i])
                let bbox1 = orderedPredictions[i].boundingBox
                for j in (i+1)..<orderedPredictions.count {
                    if keep[j] {
                        let bbox2 = orderedPredictions[j].boundingBox
                        if IoU(bbox1, bbox2) > Float(iouThreshold) {
                            keep[j] = false
                        }
                    }
                }
            }
        }

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        let actualImageBounds = imageView.frameForImageInImageViewAspectFit()
        let scaleX = actualImageBounds.width / modelImgSize
        let scaleY = actualImageBounds.height / modelImgSize
        
        for prediction in predictions {
            let bb = prediction.boundingBox

            let newBB = bb.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                .applying(CGAffineTransform(translationX: (imageView.frame.width - actualImageBounds.width)/2, y: (imageView.frame.height - actualImageBounds.height)/2))
            let shapeLayer = self.createRoundedRectLayerWithBounds(newBB)
            
//            let textLayer = self.createTextSubLayerInBounds(newBB, identifier: "petri-dish", confidence: prediction.confidence)
//            shapeLayer.addSublayer(textLayer)
            
            detectionOverlay.addSublayer(shapeLayer)

            let bbnorm = CGRect(x: bb.origin.x/modelImgSize, y: bb.origin.y/modelImgSize, width: bb.size.width/modelImgSize, height: bb.size.height/modelImgSize)
            var imgBounds = VNImageRectForNormalizedRect(bbnorm, Int(imageView.image!.size.width), Int(imageView.image!.size.height))
            imgBounds.size.height = round(imgBounds.size.height)
            imgBounds.size.width = round(imgBounds.size.width)

            petriDetections.append(PetriDish(locInView: shapeLayer.frame, locInImg: imgBounds, croppedPetriImg: imageView.image!.croppedInRect(rect: imgBounds)))
        }
        
        self.updateLayerGeometry()
        
        CATransaction.commit()
        
        if predictions.count == 0 {
            textView.text = "No Petri dishes were detected."
        } else if predictions.count == 1 {
            textView.text = "1 Petri dish was detected. Tap the Petri dish of interest to proceed with analysis."
        } else {
            textView.text = "\(predictions.count) Petri dishes were detected. Tap the Petri dish of interest to proceed with analysis."
        }
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: self.imageView.bounds.width,
                                         height: self.imageView.bounds.height)
        detectionOverlay.position = CGPoint(x: imageView.frame.midX, y: imageView.frame.midY)
        view.layer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: self.imageView.bounds.width,
                                         height: self.imageView.bounds.height)
        // center the layer
        detectionOverlay.position = CGPoint(x: imageView.frame.midX, y: imageView.frame.midY)
        CATransaction.commit()

    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: Float) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "petri-dish"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.10, 0.80, 0.35, 0.2])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    // MARK: - Other Functions
    func classifyImage(_ image: UIImage) {
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        guard let cgImage = image.cgImage else {
            fatalError("Unable to create \(CGImage.self) from \(image).")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            
            do {
                try handler.perform(self.requests)
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let loc = tapGestureRecognizer.location(in: view)
        let normLoc = CGPoint(x: loc.x-imageViewLeadingConstraint.constant, y: loc.y-view.safeAreaInsets.top)
        
        var petriDishesInTap = [PetriDish]()
        
        for petriDish in petriDetections {
            if petriDish.locInView.contains(normLoc) {
                petriDishesInTap.append(petriDish)
            }
        }
        
        // make sure tap is within 1 bounding box region only, otherwise do nothing
        if petriDishesInTap.count == 1 {
            let petriDish = petriDishesInTap[0]
            let croppedImage = petriDish.croppedPetriImg
            
            self.imgToProcess = croppedImage
            self.petriToProcess = petriDish
            
            
            if let plaqueAssayVC = plaqueAssayViewConroller, let plateID = assayPlateID {
                plaqueAssayVC.plates[plateID] = petriDish
            }
            
            self.performSegue(withIdentifier: "toCountVC", sender: self)
        }
    }
    
    public func IoU(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        let union = a.union(b)
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SelectImageViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
      
        detectionOverlay.sublayers = nil
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        imageView.image = image
        textView.isHidden = false
        helpButton.isHidden = false
        starterLabel.isHidden = true
        
        updateLayerGeometry()
        
        classifyImage(image)
    }
}
