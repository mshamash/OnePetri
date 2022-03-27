//
//  CountPlaquesViewController.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-02.
//

import UIKit
import Vision

class CountPlaquesViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backToAssayButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    
    var plaqueAssayViewConroller: PlaqueAssayViewController?
    
    var origPetriDishImage: UIImage!
    var petriDishImage: UIImage!
    var petriDish: PetriDish!
    var assaySelection: Assay!
    
    private var detectionOverlay: CALayer! = nil
    private var requests = [VNRequest]()
    private var tileArray = [Tile]()
    private var colExtraTileArray = [Tile]()
    private var rowExtraTileArray = [Tile]()
    private var mainPlaqueArray = [Plaque]()
    private var colExtraPlaqueArray = [Plaque]()
    private var rowExtraPlaqueArray = [Plaque]()
    
    private var tileWidth: CGFloat!
    private var tileHeight: CGFloat!
    private var tilesPerCol: Int!
    private var tilesPerRow: Int!
    
    let group = DispatchGroup()
    var currentTile: Tile!
    private let modelImgSize: CGFloat = 640.0
    private var confThreshold: Double!
    private var iouThreshold: Double!
    
    private var benchmark = false
    
    private var actualImageBounds: CGRect!
    
    struct Prediction {
        let labelIndex: Int
        let confidence: Float
        let boundingBox: CGRect
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.text = "Detecting plaques..."
        self.backToAssayButton.isHidden = true
        self.helpButton.isHidden = true
        
        imageView.image = petriDishImage
        
        if self.petriDishImage.size.width < modelImgSize || self.petriDishImage.size.height < modelImgSize {
            let alert = UIAlertController(title: "Invalid Petri dish", message: "The Petri dish selected is too small to proceed with analysis. Please select a higher resolution image.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Go Back", style: .cancel, handler: { _ in
                self.navigationController?.popToViewController(ofClass: SelectImageViewController.self)
            }))
            
            self.present(alert, animated: true)
        } else {
            let defaults = UserDefaults.standard
            let plaqueConfThreshold = defaults.double(forKey: "PlaqueConfThreshold")
            let plaqueIOUThreshold = defaults.double(forKey: "PlaqueIOUThreshold")
            confThreshold = (plaqueConfThreshold != 0.0 ? plaqueConfThreshold : 0.85)
            iouThreshold = (plaqueIOUThreshold != 0.0 ? plaqueIOUThreshold : 0.25)
            
            let tileTuple = petriDishImage.tileImageDynamically(networkSize: modelImgSize)
            tileArray = tileTuple.0
            colExtraTileArray = tileTuple.1
            rowExtraTileArray = tileTuple.2
            tileWidth = tileTuple.3
            tileHeight = tileTuple.4
            tilesPerCol = tileTuple.5
            tilesPerRow = tileTuple.6
            
            // setup Vision parts
            setupLayers()
            updateLayerGeometry()
            setupVision()
            
            #if DEBUG
            benchmark = true
            #endif
            
            let start = DispatchTime.now() // start time
            
            detectPlaques(tiles: tileArray) {
                print("Done main tiles!")
                self.detectPlaques(tiles: self.colExtraTileArray) {
                    print("Done extra column tiles!")
                    self.detectPlaques(tiles: self.rowExtraTileArray) {
                        print("Done extra row tiles!")
                        let end = DispatchTime.now() // end time (before NMS)
                        
                        self.nonMaximumSuppression {
                            let endNMS = DispatchTime.now() // end time (after NMS)
                            
                            if self.benchmark {
                                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // difference in nanoseconds, excluding additional NMS
                                let nanoTimeNMS = endNMS.uptimeNanoseconds - start.uptimeNanoseconds // difference in nanoseconds, including additional NMS
                                let timeInterval = Double(nanoTime) / 1_000_000_000
                                let timeIntervalNMS = Double(nanoTimeNMS) / 1_000_000_000

                                let totalNumTiles = self.tileArray.count + self.colExtraTileArray.count + self.rowExtraTileArray.count
                                
                                print("BENCHMARK;\(timeInterval);\(timeIntervalNMS);\(timeIntervalNMS-timeInterval);\(self.petriDish.plaques.count);\(self.tilesPerCol!);\(self.tilesPerRow!);\(self.tileArray.count);\(self.colExtraTileArray.count);\(self.rowExtraTileArray.count);\(totalNumTiles);\(self.tileWidth!);\(self.tileHeight!)")
                            }
                            
                            DispatchQueue.main.async{
                                if self.assaySelection != .quick { self.backToAssayButton.isHidden = false }
                                self.helpButton.isHidden = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func backToAssayPressed(_ sender: Any) {
        navigationController?.popToViewController(ofClass: PlaqueAssayViewController.self)
    }
    
    @IBAction func didTapHelp(_ sender: UIButton) {
        let alert = UIAlertController(title: "Missing plaques?", message: "If some plaques were not detected, you may submit the selected image to help improve future iterations of OnePetri's AI models. Would you like to submit this image for analysis?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Send Image", style: .default, handler: { _ in
            self.sendMail(imageMail: true, image: self.origPetriDishImage, imageType: "plaque")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = helpButton
        
        self.present(alert, animated: true)
    }
    
    // MARK: - Vision Functions
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "Yv5-plaque-res640_epochs250_v7-yv5n_v61", withExtension: "mlmodelc") else {
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
        
        // Array to store final predictions (after post-processing)
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
        
        actualImageBounds = imageView.frameForImageInImageViewAspectFit()
        
        let scaleX = actualImageBounds.width / petriDishImage.size.width
        let scaleY = actualImageBounds.height / petriDishImage.size.height
        
        let offsetX = (imageView.bounds.width-actualImageBounds.size.width)/2.0
        let offsetY = (imageView.bounds.height-actualImageBounds.size.height)/2.0
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        for prediction in predictions  {
            let bb = prediction.boundingBox
            let bbNorm = CGRect(x: bb.origin.x/modelImgSize, y: bb.origin.y/modelImgSize, width: bb.width/modelImgSize, height: bb.height/modelImgSize)
            let tempBox = VNImageRectForNormalizedRect(bbNorm, Int(tileWidth), Int(tileHeight))
            
            switch currentTile.tileType {
            case .tile:
                let objectBounds = tempBox.offsetBy(dx: currentTile.locRowColumn.x * tileWidth, dy: currentTile.locRowColumn.y * tileHeight)
                    .applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                    .applying(CGAffineTransform(translationX: offsetX, y: offsetY))

                let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds, color: [1.0, 0.0, 0.0])
                detectionOverlay.addSublayer(shapeLayer)

                mainPlaqueArray.append(Plaque(petriDish: petriDish, locInLayer: shapeLayer.bounds, plaqueLayer: shapeLayer))
                
            case .colExtraTile:
                let objectBounds = tempBox.offsetBy(dx: (currentTile.locRowColumn.x * tileWidth) - (tileWidth * 0.5), dy: currentTile.locRowColumn.y * tileHeight)
                    .applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                    .applying(CGAffineTransform(translationX: offsetX + (actualImageBounds.width / CGFloat(tilesPerRow)), y: offsetY))
                
                let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds, color: [1.0, 0.0, 0.0])
                detectionOverlay.addSublayer(shapeLayer)

                colExtraPlaqueArray.append(Plaque(petriDish: petriDish, locInLayer: shapeLayer.bounds, plaqueLayer: shapeLayer))

            case .rowExtraTile:
                let objectBounds = tempBox.offsetBy(dx: currentTile.locRowColumn.x * tileWidth, dy: (currentTile.locRowColumn.y * tileHeight) - (tileHeight * 0.5))
                    .applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                    .applying(CGAffineTransform(translationX: offsetX, y: offsetY + (actualImageBounds.height / CGFloat(tilesPerCol))))

                let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds, color: [1.0, 0.0, 0.0])
                detectionOverlay.addSublayer(shapeLayer)

                rowExtraPlaqueArray.append(Plaque(petriDish: petriDish, locInLayer: shapeLayer.bounds, plaqueLayer: shapeLayer))
            }
        }
        
        self.updateLayerGeometry()
        
        CATransaction.commit()
        
        group.leave()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: imageView.bounds.width,
                                         height: imageView.bounds.height)
        // center the layer
        detectionOverlay.position = CGPoint(x:imageView.frame.midX, y: imageView.frame.midY)
        view.layer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: imageView.bounds.width,
                                         height: imageView.bounds.height)
        // center the layer
        detectionOverlay.position = CGPoint(x:imageView.frame.midX, y: imageView.frame.midY)
        CATransaction.commit()
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect, color: [CGFloat]) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "plaque"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [color[0], color[1], color[2], 0.15])
        shapeLayer.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [color[0], color[1], color[2], 0.9])
        shapeLayer.borderWidth = 0.5
        shapeLayer.cornerRadius = 0
        return shapeLayer
    }
    
    // MARK: - Other Functions
    func detectPlaques(tiles: [Tile], finished: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            for tile in tiles {
                self.group.enter()
                self.currentTile = tile
                let orientation = CGImagePropertyOrientation(tile.tileImg.imageOrientation)
                
                guard let cgImage = tile.tileImg.cgImage else {
                    fatalError("Unable to create \(CGImage.self) from \(tile.tileImg).")
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                
                do {
                    try handler.perform(self.requests)
                } catch {
                    print("Failed to perform classification.\n\(error.localizedDescription)")
                }
                self.group.wait()
            }
            finished()
        }
    }
    
    func summarizePlaques(plaqueArray: [Plaque]? = nil) {
        print("===== START OF PLAQUE COUNTS =====")
        if let plaqueArray = plaqueArray {
            print("Total plaque count after NMS is: \(plaqueArray.count)")
            let s = (plaqueArray.count == 1) ?  "" : "s"
            DispatchQueue.main.async {
                self.textView.text = "\(plaqueArray.count) plaque\(s) detected"
            }
        } else {
            print("mainPlaqueArray count is: \(mainPlaqueArray.count)")
            print("colExtraPlaqueArray plaque array count is: \(colExtraPlaqueArray.count)")
            print("rowExtraPlaqueArray plaque array count is: \(rowExtraPlaqueArray.count)")
        }
        print("===== END OF PLAQUE COUNTS =====")
    }
    
    func nonMaximumSuppression(finished: @escaping () -> Void) {
        summarizePlaques()
        
        //all vs all comparison
        var mergedArray = mainPlaqueArray + colExtraPlaqueArray + rowExtraPlaqueArray
        for plaque in mergedArray {
            for otherPlaque in mergedArray {
                if plaque !== otherPlaque {
                    let plaqueLayerBds = plaque.locInLayer
                    let otherPlaqueLayerBds = otherPlaque.locInLayer
                    let intersection = plaqueLayerBds.intersection(otherPlaqueLayerBds)
                    
                    if !intersection.isNull {
                        let intersectionArea = intersection.width * intersection.height
                        let plaqueArea = plaqueLayerBds.width * plaqueLayerBds.height
                        let otherPlaqueArea = otherPlaqueLayerBds.width * otherPlaqueLayerBds.height
                        
                        let areaOverPlaque = intersectionArea / plaqueArea
                        let areaOverOtherPlaque = intersectionArea / otherPlaqueArea
                        
                        if (areaOverPlaque > areaOverOtherPlaque) && (areaOverPlaque >= CGFloat(iouThreshold)) {
                            DispatchQueue.main.async{ self.detectionOverlay.sublayers!.removeAll(where: {$0 === plaque.plaqueLayer}) }
                            mergedArray.removeAll(where: {$0 === plaque})
                        } else if (areaOverOtherPlaque > areaOverPlaque) && (areaOverOtherPlaque >= CGFloat(iouThreshold)) {
                            DispatchQueue.main.async{ self.detectionOverlay.sublayers!.removeAll(where: {$0 === otherPlaque.plaqueLayer}) }
                            mergedArray.removeAll(where: {$0 === otherPlaque})
                        }
                    }
                }
            }
        }
        petriDish.plaques = mergedArray
        summarizePlaques(plaqueArray: mergedArray)
        finished()
    }
    
    func drawRectangleOnImage(image: UIImage, rect: CGRect) -> UIImage {
        let imageSize = image.size
        let scale: CGFloat = image.scale
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        image.draw(at: CGPoint.zero)
        
        UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.2).setFill()
        UIRectFill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    public func IoU(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        let union = a.union(b)
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
    
}
