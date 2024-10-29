//
//  RegisterMenu.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct Int8LayerMenu: View {
    @Binding var selectedLayer: UInt8
    
    let layers: [UInt8] = Array(0...7)

    var body: some View {
        Menu {
            ForEach(layers, id: \.self) { layer in
                Button(action: {
                    selectedLayer = layer
                    Game.shared.cpuRender.update()
                }) {
                    Text("L\(layer)")
                }
            }
        } label: {
            Text("L\(selectedLayer)")
        }
        .frame(width: 60)
        .menuStyle(DefaultMenuStyle())
    }
}
