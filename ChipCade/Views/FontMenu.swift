//
//  RegisterMenu.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

let fonts = ["OpenSans", "SquadaOne", "Square"]

struct FontMenu: View {
    @Binding var currentFont: String
    
    var body: some View {
        Menu {
            ForEach(fonts, id: \.self) { newValue in
                Button(action: {
                    currentFont = newValue
//                    Game.shared.cpuRender.update()
                }) {
                    Text(newValue)
                }
            }
        } label: {
            Text(currentFont)
        }
        .frame(minWidth: 120)
        .menuStyle(DefaultMenuStyle())
    }
}
