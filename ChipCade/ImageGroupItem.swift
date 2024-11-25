//
//  SpriteItem.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import Combine
import SwiftUI

class ImageGroupItem : ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID
    var intId: Int

    @Published var images: [Data]
    @Published var name: String

    private enum CodingKeys: String, CodingKey {
        case id, intId, images, name
    }
    
    init(name: String, intId: Int) {
        self.id = UUID()
        self.name = name
        self.images = []
        self.intId = intId
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        if let intId = try container.decodeIfPresent(Int.self, forKey: .intId) {
            self.intId = intId
        } else {
            self.intId = 0
        }
        images = try container.decode([Data].self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(intId, forKey: .intId)
        try container.encode(images, forKey: .images)
        try container.encode(name, forKey: .name)
    }
    
    func rename(to newName: String, using undoManager: UndoManager?, setSelectedItem: @escaping (ImageGroupItem?) -> Void) {
        let previousName = self.name
        self.name = newName

        // Trigger a UI update by setting the selected item
        setSelectedItem(self)

        // Register undo action to restore the previous name
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            targetSelf.name = previousName
            setSelectedItem(targetSelf)  // Set as selected again after undo

            // Register redo action to rename the item again
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.rename(to: newName, using: undoManager, setSelectedItem: setSelectedItem)
            }
        }
        undoManager?.setActionName("Rename Sprite Item")
    }
    
    static func == (lhs: ImageGroupItem, rhs: ImageGroupItem) -> Bool {
        return lhs.id == rhs.id
    }
}

import Cocoa

extension ImageGroupItem {
    static func createFromTilemap(tilemapData: Data, tileSize: CGFloat, name: String) -> ImageGroupItem? {
        // Create an NSImage from the data
        guard let image = NSImage(data: tilemapData) else {
            print("Failed to create image from data")
            return nil
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to get CGImage from NSImage")
            return nil
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        // Validate the tile size
        guard tileSize > 0, imageWidth.truncatingRemainder(dividingBy: tileSize) == 0, imageHeight.truncatingRemainder(dividingBy: tileSize) == 0 else {
            print("Tile size must evenly divide image dimensions")
            return nil
        }
        
        let tilesPerRow = Int(imageWidth / tileSize)
        let tilesPerColumn = Int(imageHeight / tileSize)
        var tileDataList: [Data] = []
        
        // Split the image into tiles
        for row in 0..<tilesPerColumn {
            for col in 0..<tilesPerRow {
                let tileRect = CGRect(
                    x: CGFloat(col) * tileSize,
                    y: CGFloat(row) * tileSize,
                    width: tileSize,
                    height: tileSize
                )
                
                guard let tileCgImage = cgImage.cropping(to: tileRect) else {
                    print("Failed to crop tile at row \(row), col \(col)")
                    continue
                }
                
                let tileImage = NSImage(cgImage: tileCgImage, size: NSSize(width: tileSize, height: tileSize))
                guard let tiffData = tileImage.tiffRepresentation,
                      let tileBitmap = NSBitmapImageRep(data: tiffData),
                      let tilePngData = tileBitmap.representation(using: .png, properties: [:]) else {
                    print("Failed to generate PNG data for tile at row \(row), col \(col)")
                    continue
                }
                
                tileDataList.append(tilePngData)
            }
        }
        
        // Create and return the ImageGroupItem
        let imageGroupItem = ImageGroupItem(name: name, intId: 0)
        imageGroupItem.images = tileDataList
        return imageGroupItem
    }
}
