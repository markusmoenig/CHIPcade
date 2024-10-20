//
//  RegisterMenu.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct Int8VisibleMenu: View {
    @Binding var visible: Int8
    
    let values: [Int8] = Array(0...1)

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
