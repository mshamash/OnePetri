//
//  Tile.swift
//  OnePetri
//
//  Created by Michael Shamash on 2021-07-05.
//

import UIKit

class Tile {
    
    // MARK: - Properties
    let tileImg: UIImage
    let tileCoords: CGRect
    let locRowColumn: CGPoint
    let tileType: TileTypes
    enum TileTypes { case tile, colExtraTile, rowExtraTile }
    
    // MARK: - Lifecycle
    init(tileImg: UIImage, tileCoords: CGRect, locRowColumn: CGPoint, tileType: TileTypes) {
        self.tileImg = tileImg
        self.tileType = tileType
        self.locRowColumn = locRowColumn
        self.tileCoords = tileCoords
    }

}
