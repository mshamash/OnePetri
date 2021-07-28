//
//  ScaleImage.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-06-20.
//

import UIKit

extension UIImage {
    func tileImageDynamically(networkSize: CGFloat) -> ([Tile], [Tile], [Tile], CGFloat, CGFloat, Int, Int) {
        let correctedImg = removeRotationForImage(image: self)
        
        let tilesPerCol = Int(round(self.size.height / networkSize))
        let tilesPerRow = Int(round(self.size.width / networkSize))
        
        let tileHeight = self.size.height / CGFloat(tilesPerCol)
        let tileWidth = self.size.width / CGFloat(tilesPerRow)
        
        var tileArray = [Tile]()
        
        let tileSize = CGSize(width: tileWidth, height: tileHeight)
        
        var currentCol = 0
        var currentRow = 0
        
        for y in stride(from: 0, to: tilesPerCol, by: 1) {
            currentCol = 0
            for x in stride(from: 0, to: tilesPerRow, by: 1) {
                UIGraphicsBeginImageContextWithOptions(tileSize, false, 0)
                let tileCoords = CGRect.init(x: CGFloat(x) * tileSize.width * scale, y:  CGFloat(y) * tileSize.height * scale  , width: (tileSize.width * scale) , height: (tileSize.height * scale))
                if let i =  correctedImg.cgImage?.cropping(to:  tileCoords) {
                    let newImg = UIImage.init(cgImage: i, scale: scale, orientation: correctedImg.imageOrientation)
                    let tile = Tile(tileImg: newImg, tileCoords: tileCoords, locRowColumn: CGPoint(x: currentCol, y: currentRow), tileType: .tile)
                    tileArray.append(tile)
                }
                UIGraphicsEndImageContext();
                currentCol += 1
            }
            currentRow += 1
        }
        
        var colExtraTileArray = [Tile]()
        currentCol = 0
        currentRow = 0
        
        for row in stride(from: 0, to: tilesPerCol, by: 1) {
            currentCol = 0
            for col in stride(from: 1, to: tilesPerRow, by: 1) {
                UIGraphicsBeginImageContextWithOptions(tileSize, false, 0)
                let tileCoords = CGRect.init(x: (CGFloat(col) * tileSize.width * scale)-tileSize.width/4.0, y: CGFloat(row) * tileSize.height * scale, width: (tileSize.width * scale / 2.0), height: (tileSize.height * scale))
                if let i = correctedImg.cgImage?.cropping(to: tileCoords) {
                    let newImg = UIImage.init(cgImage: i, scale: scale, orientation: correctedImg.imageOrientation)
                    let tile = Tile(tileImg: newImg, tileCoords: tileCoords, locRowColumn: CGPoint(x: currentCol, y: currentRow), tileType: .colExtraTile)
                    colExtraTileArray.append(tile)
                }
                UIGraphicsEndImageContext();
                currentCol += 1
            }
            currentRow += 1
        }
        
        var rowExtraTileArray = [Tile]()
        currentCol = 0
        currentRow = 0
        
        for col in stride(from: 1, to: tilesPerRow, by: 1) {
            currentCol = 0
            for row in stride(from: 0, to: tilesPerCol, by: 1) {
                UIGraphicsBeginImageContextWithOptions(tileSize, false, 0)
                let tileCoords =  CGRect.init(x: CGFloat(row) * tileSize.width * scale, y: (CGFloat(col) * tileSize.height * scale)-tileSize.height/4.0, width: (tileSize.width * scale), height: (tileSize.height * scale / 2.0))
                if let i = correctedImg.cgImage?.cropping(to: tileCoords) {
                    let newImg = UIImage.init(cgImage: i, scale: scale, orientation: correctedImg.imageOrientation)
                    let tile = Tile(tileImg: newImg, tileCoords: tileCoords, locRowColumn: CGPoint(x: currentCol, y: currentRow), tileType: .rowExtraTile)
                    rowExtraTileArray.append(tile)
                }
                UIGraphicsEndImageContext();
                currentCol += 1
            }
            currentRow += 1
        }
        
        return (tileArray, colExtraTileArray, rowExtraTileArray, tileWidth, tileHeight, tilesPerCol, tilesPerRow)
    }
    
    func croppedInRect(rect: CGRect) -> UIImage {
        func rad(_ degree: Double) -> CGFloat {
            return CGFloat(degree / 180.0 * .pi)
        }

        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: rad(90)).translatedBy(x: 0, y: -self.size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: rad(-90)).translatedBy(x: -self.size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: rad(-180)).translatedBy(x: -self.size.width, y: -self.size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: self.scale, y: self.scale)

        let imageRef = self.cgImage!.cropping(to: rect.applying(rectTransform))
        let result = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return result
    }
    
    func removeRotationForImage(image: UIImage) -> UIImage {
        if image.imageOrientation == UIImage.Orientation.up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size))
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}

extension UIImageView {
    func frameForImageInImageViewAspectFit() -> CGRect {
        if let img = self.image {
            let imageRatio = img.size.width / img.size.height;
            let viewRatio = self.frame.size.width / self.frame.size.height;
            
            if(imageRatio < viewRatio) {
                let scale = self.frame.size.height / img.size.height;
                let width = scale * img.size.width;
                let topLeftX = (self.frame.size.width - width) * 0.5;
                return CGRect(x: topLeftX, y: 0, width: width, height: self.frame.size.height)
            } else {
                let scale = self.frame.size.width / img.size.width;
                let height = scale * img.size.height;
                let topLeftY = (self.frame.size.height - height) * 0.5;
                return CGRect(x: 0, y: topLeftY, width: self.frame.size.width, height: height)
            }
        }
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            @unknown default: fatalError("Unknown orientation detected, cannot proceed")
        }
    }
}
