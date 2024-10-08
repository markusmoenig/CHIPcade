//
//  RegisterMenu.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct Int8RegisterMenu: View {
    @Binding var selectedRegister: Int8
    
    let registers: [Int8] = Array(0...7)

    var body: some View {
        Menu {
            ForEach(registers, id: \.self) { register in
                Button(action: {
                    selectedRegister = register
                    Game.shared.cpuRender.update()
                }) {
                    Text("R\(register)")
                }
            }
        } label: {
            Text("R\(selectedRegister)")
        }
        .frame(width: 60)
        .menuStyle(DefaultMenuStyle())
    }
}
