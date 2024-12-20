//
//  RegisterMenu.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct Int8VisibleMenu: View {
    @Binding var visible: UInt8
    
    let values: [UInt8] = Array(0...1)

    var body: some View {
        Menu {
            ForEach(values, id: \.self) { newValue in
                Button(action: {
                    visible = newValue
                    Game.shared.cpuRender.update()
                }) {
                    Text(newValue == 0 ? "Invisible" : "Visible")
                }
            }
        } label: {
            Text(visible == 0 ? "Invisible" : "Visible")
        }
        .menuStyle(DefaultMenuStyle())
    }
}

struct Int8OnOffMenu: View {
    @Binding var on: UInt8
    
    let values: [UInt8] = Array(0...1)

    var body: some View {
        Menu {
            ForEach(values, id: \.self) { newValue in
                Button(action: {
                    on = newValue
                    Game.shared.cpuRender.update()
                }) {
                    Text(newValue == 0 ? "Off" : "On")
                }
            }
        } label: {
            Text(on == 0 ? "Off" : "On")
        }
        .menuStyle(DefaultMenuStyle())
    }
}
