//
//  MapTools.swift
//  CHIPcade
//
//  Created by Markus Moenig on 25/11/24.
//

import SwiftUI

struct MapToolBar: View {
    @Binding var selectedTool: MapEditorTool

    var body: some View {
        VStack(spacing: 6) {
            MapToolButton(tool: .select, selectedTool: $selectedTool)
            MapToolButton(tool: .vertex, selectedTool: $selectedTool)
            MapToolButton(tool: .linedefs, selectedTool: $selectedTool)
            MapToolButton(tool: .sector, selectedTool: $selectedTool)
        }
        .padding(6)
        .background(Color.secondary.opacity(0.8))
        .cornerRadius(6)
        .shadow(radius: 2)
    }
}

struct MapToolButton: View {
    let tool: MapEditorTool
    @Binding var selectedTool: MapEditorTool

    var body: some View {
        Button(action: {
            selectedTool = tool
        }) {
            Image(systemName: tool.iconName) // Use appropriate SF Symbols
                .resizable()
                .frame(width: 14, height: 14)
                .padding(6)
                .background(selectedTool == tool ? Color.blue : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(selectedTool == tool ? .white : .black)
        .animation(.easeInOut(duration: 0.2), value: selectedTool)
    }
}
