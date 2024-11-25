//
//  MapWidget.swift
//  CHIPcade
//
//  Created by Markus Moenig on 24/11/24.
//

import Foundation
import SwiftUI

import MetalKit
import Combine

enum MapEditorMode {
    case mode2D
    case mode3D

    var displayName: String {
        switch self {
        case .mode2D: return "2D Mode"
        case .mode3D: return "3D Mode"
        }
    }

    var iconName: String {
        switch self {
        case .mode2D: return "square.grid.2x2"
        case .mode3D: return "cube"
        }
    }
}

enum MapEditorTool {
    case select
    case vertex
    case linedefs
    case sector

    var displayName: String {
        switch self {
        case .select: return "Select Tool"
        case .vertex: return "Vertex Tool"
        case .linedefs: return "Linedef Tool"
        case .sector: return "Sector Tool"
        }
    }
    
    var iconName: String {
        switch self {
        case .select: return "cursorarrow"
        case .vertex: return "circle"
        case .linedefs: return "line.diagonal"
        case .sector: return "square.stack.3d.up"
        }
    }
}

public class MapWidget
{
    var screenSize: float2 = .zero
    
    var currMode: MapEditorMode = .mode2D
    var currTool: MapEditorTool = .linedefs
    
    var currGridPos: float2? = nil
    var currMousePos: float2? = nil

    func mouseDown(pos: float2, gridPos: float2, mapItem: inout MapItem, undoManager: UndoManager?) {
        if currTool == .linedefs {
            
            if let currGridPos = currGridPos {
                if currGridPos.x != gridPos.x || currGridPos.y != gridPos.y {
                    // Add new linedef
                    addLinedef(from: currGridPos, to: gridPos, mapItem: mapItem, undoManager: undoManager)
                    if let (loopVertices, loopLinedefs) = findClosedLoop(mapItem: mapItem) {
                        if isValidPolygon(vertices: loopVertices, mapItem: mapItem) {
                            createSector(from: loopVertices, loopLinedefs: loopLinedefs, mapItem: mapItem, undoManager: undoManager)
                            updateSectorNeighbors(mapItem: &mapItem)
                            update()

                            self.currGridPos = nil
                            self.currMousePos = nil
                            
                            return
                        }
                    }
                }
            }
            
            self.currGridPos = gridPos
            self.currMousePos = pos
        }
        update()
    }

    func mouseDragged(pos: float2, gridPos: float2, mapItem: MapItem) {
        
    }
    
    func mouseMoved(pos: float2, gridPos: float2, mapItem: MapItem) {
        self.currMousePos = gridToScreen(gridPos: gridPos, mapItem: mapItem)
        update()
    }
    
    func mouseUp(pos: float2, gridPos: float2, mapItem: MapItem) {
        
    }
    
    func draw(draw2D: MetalDraw2D, mapItem: MapItem, game: Game)
    {
        draw2D.encodeStart(.clear)
//        draw2D.drawBox(position: float2(10, 10), size: float2(200, 100), rounding: 10.0, borderSize: 4, onion: 0.0, fillColor: float4(1, 0.5, 0.2, 1), borderColor: float4(0.5, 1, 0.2, 1))
        draw2D.drawGrid(offset: mapItem.offset, gridSize: mapItem.gridSize, backgroundColor: float4(1, 0, 0, 1))
        
        // Draw sectors
        for (_, sector) in mapItem.sectors {
            let vertexCount = sector.vertices.count
            guard vertexCount >= 3 else { continue }
            
            draw2D.startShape(type: .triangleStrip)
            for vertexIndex in sector.vertices {
                guard let vertex = mapItem.vertices[vertexIndex] else { continue }
                let pos = gridToScreen(gridPos: vertex.float2D(), mapItem: mapItem)
                
                let gridPos = vertex.float2D()
                let texCoord = (gridPos - mapItem.offset) / (mapItem.gridSize * float2(mapItem.gridSize, mapItem.gridSize))

                draw2D.addVertex(pos, texCoord, float4(1, 0, 0, 1))
            }
            draw2D.endShape()
        }
        
        // Draw linedefs
        for (_, line) in mapItem.linedefs {
            let startVertex = mapItem.vertices[line.startVertex]!
            let endVertex = mapItem.vertices[line.endVertex]!
            
            let startPos = gridToScreen(gridPos: startVertex.float2D(), mapItem: mapItem)
            let endPos = gridToScreen(gridPos: endVertex.float2D(), mapItem: mapItem)
            
            draw2D.drawLine(startPos: startPos, endPos: endPos, radius: 1)
        }
        
        // Draw open line ?
        if let currGridPos = currGridPos, let currMousePos = currMousePos {
            let g = gridToScreen(gridPos: currGridPos, mapItem: mapItem)
            
            draw2D.drawLine(startPos: g, endPos: currMousePos, radius: 1)
            //draw2D.drawLine(startPos: .zero, endPos: float2(200, 200), radius: 2)
        }
        
        draw2D.encodeEnd()
    }
    
    /// Add a new linedef
    func addLinedef(from startGridPos: float2, to endGridPos: float2, mapItem: MapItem, undoManager: UndoManager?) {

        func findExistingVertex(at position: float2, in vertices: [Int: Vertex]) -> Int? {
            return vertices.first(where: { $0.value.x == position.x && $0.value.y == position.y })?.key
        }

        // Check for existing vertices
        var startVertexID = findExistingVertex(at: startGridPos, in: mapItem.vertices)
        var endVertexID = findExistingVertex(at: endGridPos, in: mapItem.vertices)

        if startVertexID == nil {
            startVertexID = mapItem.vertices.count
            let startVertex = Vertex(id: startVertexID!, x: startGridPos.x, y: startGridPos.y)
            mapItem.vertices[startVertexID!] = startVertex
        }
        if endVertexID == nil {
            endVertexID = mapItem.vertices.count
            let endVertex = Vertex(id: endVertexID!, x: endGridPos.x, y: endGridPos.y)
            mapItem.vertices[endVertexID!] = endVertex
        }

        let linedef = Linedef(
            id: mapItem.linedefs.count,
            startVertex: startVertexID!,
            endVertex: endVertexID!,
            texture: nil,
            isPortal: false,
            frontSector: -1,
            backSector: nil
        )

        // Add linedef to the map
        mapItem.linedefs[linedef.id] = linedef

        // Undo and Redo Support
        undoManager?.registerUndo(withTarget: mapItem) { targetMap in
            targetMap.linedefs.removeValue(forKey: linedef.id)

            if !targetMap.linedefs.values.contains(where: { $0.startVertex == startVertexID || $0.endVertex == startVertexID }) {
                targetMap.vertices.removeValue(forKey: startVertexID!)
            }

            if !targetMap.linedefs.values.contains(where: { $0.startVertex == endVertexID || $0.endVertex == endVertexID }) {
                targetMap.vertices.removeValue(forKey: endVertexID!)
            }

            self.abortAction()
            undoManager?.registerUndo(withTarget: targetMap) { redoTargetMap in
                self.abortAction()
                self.addLinedef(
                    from: startGridPos,
                    to: endGridPos,
                    mapItem: redoTargetMap,
                    undoManager: undoManager
                )
            }
        }
        undoManager?.setActionName("Add Linedef")
    }
    
    /// Checks if a given Linedef closes a loop
    func findClosedLoop(mapItem: MapItem) -> ([Int], [Linedef])? {
        // Find the last added linedef
        guard let lastKey = mapItem.linedefs.keys.max(),
              let lastLinedef = mapItem.linedefs[lastKey] else {
            return nil
        }

        var visitedLinedefs = Set<Int>() // Track visited linedefs by ID
        var currentLinedef = lastLinedef
        var loopVertices = [currentLinedef.startVertex] // Start from the first vertex
        var loopLinedefs = [currentLinedef] // Include the last linedef

        while true {
            // Mark the current linedef as visited
            visitedLinedefs.insert(currentLinedef.id)

            // Find the next linedef connected to the current one
            if let nextLinedef = mapItem.linedefs.values.first(where: {
                !visitedLinedefs.contains($0.id) && $0.startVertex == currentLinedef.endVertex
            }) {
                // Add the vertex and linedef to the loop
                loopVertices.append(nextLinedef.startVertex)
                loopLinedefs.append(nextLinedef)

                // Check for closure
                if nextLinedef.endVertex == lastLinedef.startVertex {
                    loopVertices.append(nextLinedef.endVertex) // Add the closing vertex
                    return (loopVertices, loopLinedefs)
                }

                // Move to the next linedef
                currentLinedef = nextLinedef
            } else {
                break // No more connected linedefs, stop the traversal
            }
        }

        return nil // No closed loop found
    }
    
    func isValidPolygon(vertices: [Int], mapItem: MapItem) -> Bool {
        // Remove the duplicate last vertex before validation
        let processedVertices = Array(vertices.dropLast())

        // Check for simple polygon (no duplicate vertices in the loop)
        let uniqueVertices = Set(processedVertices)
        return uniqueVertices.count == processedVertices.count
    }
    
    func createSector(from loopVertices: [Int], loopLinedefs: [Linedef], mapItem: MapItem, undoManager: UndoManager?) {
        let newSectorID = (mapItem.sectors.keys.max() ?? 0) + 1
        
        let newSector = Sector(
            id: newSectorID,
            vertices: loopVertices,
            floorHeight: 0.0,         // Default floor height
            ceilingHeight: 10.0,     // Default ceiling height
            floorTexture: "default_floor",  // Placeholder floor texture
            ceilingTexture: "default_ceiling",  // Placeholder ceiling texture
            lightLevel: 1.0,         // Full brightness
            neighbors: []            // Neighbors will be computed later
        )

        // Add sector to map
        mapItem.sectors[newSectorID] = newSector

        // Update the linedefs' front/back sectors
        var modifiedLinedefs: [(Linedef, Int?)] = []
        for linedef in loopLinedefs {
            if linedef.frontSector == -1 {
                modifiedLinedefs.append((linedef, linedef.frontSector)) // Store original value
                mapItem.linedefs[linedef.id]?.frontSector = newSectorID
            } else if linedef.backSector == -1 {
                modifiedLinedefs.append((linedef, linedef.backSector)) // Store original value
                mapItem.linedefs[linedef.id]?.backSector = newSectorID
            }
        }

        // Undo support
        undoManager?.registerUndo(withTarget: mapItem) { targetMap in
            targetMap.sectors.removeValue(forKey: newSectorID)

            for (linedef, originalValue) in modifiedLinedefs {
                if let originalValue = originalValue {
                    if linedef.frontSector == newSectorID {
                        targetMap.linedefs[linedef.id]?.frontSector = originalValue
                    } else if linedef.backSector == newSectorID {
                        targetMap.linedefs[linedef.id]?.backSector = originalValue
                    }
                }
            }

            self.abortAction()
            // Register redo when undo is performed
            undoManager?.registerUndo(withTarget: targetMap) { redoTargetMap in
                self.abortAction()
                self.createSector(
                    from: loopVertices,
                    loopLinedefs: loopLinedefs,
                    mapItem: redoTargetMap,
                    undoManager: undoManager
                )
            }
        }
        undoManager?.setActionName("Create Sector")
    }
    
    func updateSectorNeighbors(mapItem: inout MapItem) {
        for (_, linedef) in mapItem.linedefs {
            // Ensure the front sector is valid
            guard let frontSector = mapItem.sectors[linedef.frontSector] else {
                continue
            }

            // Safely unwrap and process the back sector if it exists
            if let backSectorID = linedef.backSector,
               let backSector = mapItem.sectors[backSectorID] {

                // Update neighbors for frontSector
                if !frontSector.neighbors.contains(backSectorID) {
                    mapItem.sectors[frontSector.id]?.neighbors.append(backSectorID)
                }

                // Update neighbors for backSector
                if !backSector.neighbors.contains(frontSector.id) {
                    mapItem.sectors[backSector.id]?.neighbors.append(frontSector.id)
                }
            } else {
                print("Linedef \(linedef.id) has no valid backSector.")
            }
        }
    }
    
    /// Redraw
    private func update() {
        Game.shared.mapRender.update()
    }
    
    /// Converts the logical grid position to a screen coordinate.
    func gridToScreen(gridPos: float2, mapItem: MapItem) -> float2 {
        let gridSpacePos = gridPos * mapItem.gridSize
        let screenPos = gridSpacePos + float2(-mapItem.offset.x, mapItem.offset.y) + screenSize / 2.0
        return screenPos
    }
    
    // User pressed Escape or an Undo occured. Escape the current action
    func abortAction() {
        currGridPos = nil
        currMousePos = nil
        
        update()
    }
    
    func colorToFloat4(_ color: Color) -> simd_float4 {
        #if os(iOS)
        // iOS uses UIColor
        let uiColor = UIColor(color) // Try to initialize directly from SwiftUI Color
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Ensure color is in RGB color space and extract the components
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        alpha = 1.0
        
        #elseif os(macOS)
        // macOS uses NSColor, convert it to sRGB space before extracting components
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white // Fallback to white if conversion fails
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return simd_float4(Float(red), Float(green), Float(blue), Float(alpha))
    }
}
