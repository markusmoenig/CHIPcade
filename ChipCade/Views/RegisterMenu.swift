//
//  RegisterMenu.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct Int8RegisterMenu: View {
    @Binding var selectedRegister: UInt8
    
    let registers: [UInt8] = Array(0...7)

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

struct Int8FullRegisterMenu: View {
    @Binding var selectedRegister: UInt8
    
    let registers: [UInt8] = Array(0...11)

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
