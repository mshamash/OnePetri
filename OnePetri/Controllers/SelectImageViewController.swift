//
//  SelectImageViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-06-20.
//

import UIKit
import Vision

class SelectImageViewController: UIViewController {
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!

    // MARK: - Properties
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var starterLabel: UILabel!
    
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    
    var plaqueAssayViewConroller: PlaqueAssayViewController?
    var assayPlateID: Int?
    
    var petriDishImage: UIImage?
    var assaySelection: Assay!
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    
    private var petriDetections = [PetriDish]()
    private var imgToProcess: UIImage!
    private var petriToProcess: PetriDish!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        let largeQuestionMark = UIImage(systemName: "questionmark.circle", withConfiguration: largeConfig)
        let largePhoto = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: largeConfig)
        let largeCamera = UIImage(systemName: "camera.fill", withConfiguration: largeConfig)
        helpButton.setImage(largeQuestionMark, for: .normal)
        photoLibraryButton.setImage(largePhoto, for: .normal)
        cameraButton.setImage(largeCamera, for: .normal)
        
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
                destination.petriDishImage = imgToProcess
                destination.petriDish = petriToProcess
                destination.assaySelection = assaySelection
            }
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let loc = tapGestureRecognizer.location(in: view)
//        let normLoc = CGPoint(x: loc.x-imageViewLeadingConstraint.constant, y: loc.y-imageViewTopPaddingConstraint.constant)
        let normLoc = CGPoint(x: loc.x-imageViewLeadingConstraint.constant, y: loc.y-view.safeAreaInsets.top)
        
        for petriDish in petriDetections {
            if petriDish.locInView.contains(normLoc) {
                let croppedImage = petriDish.croppedPetriImg
                
                self.imgToProcess = croppedImage
                self.petriToProcess = petriDish
                
                
                if let plaqueAssayVC = plaqueAssayViewConroller, let plateID = assayPlateID {
                    plaqueAssayVC.plates[plateID] = petriDish
                }
                
                self.performSegue(withIdentifier: "toCountVC", sender: self)
            }
        }
    }
    
    @IBAction func didTapHelp(_ sender: UIButton) {
        let alert = UIAlertController(title: "Missing petri dish?", message: "If a petri dish was not detected, you may submit the selected image for incorporation into future iterations of the app's AI models. Would you like to submit this image for analysis?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Send Image", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)

    }
  
    // MARK: - Actions
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
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "Yv5-petri-res320_epoch500_v4", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            visionModel.featureProvider = ModelFeatureProvider(iouThreshold: 0.35, confidenceThreshold: 0.70)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            objectRecognition.imageCropAndScaleOption = .scaleFit
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        petriDetections = [PetriDish]()
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            
            let actualImageBounds = imageView.frameForImageInImageViewAspectFit()
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(actualImageBounds.width), Int(actualImageBounds.height))
            
            let newOriginX = objectBounds.origin.x + (imageView.frame.width - actualImageBounds.width)/2
            let newOriginY = objectBounds.origin.y + (imageView.frame.height - actualImageBounds.height)/2
            
            let boundingBox = CGRect(x: newOriginX, y: newOriginY, width: objectBounds.width, height: objectBounds.height)
            
            let transformVerticalAxis = CGAffineTransform(scaleX: 1, y: -1)
            let newBB = boundingBox.applying(transformVerticalAxis.translatedBy(x: 0, y: -imageView.bounds.size.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(newBB)
            

            let textLayer = self.createTextSubLayerInBounds(newBB, identifier: objectObservation.labels[0].identifier, confidence: objectObservation.confidence)
            
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            
            let imgBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(imageView.image!.size.width), Int(imageView.image!.size.height))
            var transformedImgBounds = imgBounds.applying(transformVerticalAxis.translatedBy(x: 0, y: -imageView.image!.size.height))
            transformedImgBounds.size.height = round(transformedImgBounds.size.height)
            transformedImgBounds.size.width = round(transformedImgBounds.size.width)
            
            petriDetections.append(PetriDish(locInView: shapeLayer.frame, locInImg: transformedImgBounds, croppedPetriImg: imageView.image!.croppedInRect(rect: transformedImgBounds)))
        }
        self.updateLayerGeometry()
        
        CATransaction.commit()
        
        if results.count == 0 {
            textView.text = "No petri dishes were detected."
        } else if results.count == 1 {
            textView.text = "1 petri dish was detected. Tap the petri dish of interest to proceed with analysis."
        } else {
            textView.text = "\(results.count) petri dishes were detected. Tap the petri dish of interest to proceed with analysis."
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
//        detectionOverlay.backgroundColor = CGColor(red: 255, green: 0, blue: 0, alpha: 0.3)
//        detectionOverlay.borderColor = CGColor(red: 255, green: 0, blue: 0, alpha: 1)
//        detectionOverlay.borderWidth = CGFloat(3.0)
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
//        let origin = CGRect(x: 0, y: 0, width: 10, height: 10)
//        let originShape = self.createRoundedRectLayerWithBounds(origin)
//        detectionOverlay.addSublayer(originShape)

    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
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
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.3])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
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
}

// MARK: - UIImagePickerControllerDelegate
extension SelectImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
