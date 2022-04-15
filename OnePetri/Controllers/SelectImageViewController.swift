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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        let petriConfThreshold = defaults.double(forKey: "PetriConfThreshold")
        let petriIOUThreshold = defaults.double(forKey: "PetriIOUThreshold")
        confThreshold = (petriConfThreshold != 0.0 ? petriConfThreshold : 0.50)
        iouThreshold = (petriIOUThreshold != 0.0 ? petriIOUThreshold : 0.35)
        
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
        
        guard let modelURL = Bundle.main.url(forResource: "Yv5-petri-res640_epochs500_v4-yv5n_v61.quant", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            visionModel.featureProvider = ModelFeatureProvider(iouThreshold: iouThreshold, confidenceThreshold: confThreshold)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { [weak self] (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self?.drawVisionRequestResults(results)
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
        petriDetections = [PetriDish]()
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        let actualImageBounds = imageView.frameForImageInImageViewAspectFit()
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            
            let bb = objectObservation.boundingBox
            
            let objectBounds = VNImageRectForNormalizedRect(bb, Int(actualImageBounds.width), Int(actualImageBounds.height))
            
            let newOriginX = objectBounds.origin.x + (imageView.frame.width - actualImageBounds.width)/2
            let newOriginY = objectBounds.origin.y + (imageView.frame.height - actualImageBounds.height)/2
            
            let boundingBox = CGRect(x: newOriginX, y: newOriginY, width: objectBounds.width, height: objectBounds.height)
            
            let transformVerticalAxis = CGAffineTransform(scaleX: 1, y: -1)
            let newBB = boundingBox.applying(transformVerticalAxis.translatedBy(x: 0, y: -imageView.bounds.size.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(newBB)
            detectionOverlay.addSublayer(shapeLayer)
            
            
            let imgBounds = VNImageRectForNormalizedRect(bb, Int(imageView.image!.size.width), Int(imageView.image!.size.height))
            var transformedImgBounds = imgBounds.applying(transformVerticalAxis.translatedBy(x: 0, y: -imageView.image!.size.height))
            transformedImgBounds.size.height = round(transformedImgBounds.size.height)
            transformedImgBounds.size.width = round(transformedImgBounds.size.width)
            
            petriDetections.append(PetriDish(locInView: shapeLayer.frame, locInImg: transformedImgBounds, croppedPetriImg: imageView.image!.croppedInRect(rect: transformedImgBounds)))
        }

        self.updateLayerGeometry()
        
        CATransaction.commit()
        
        if results.count == 0 {
            textView.text = "No Petri dishes detected"
        } else if results.count == 1 {
            textView.text = "1 Petri dish detected\nTap the Petri dish to continue"
        } else {
            textView.text = "\(results.count) Petri dishes detected\nTap a Petri dish to continue"
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
