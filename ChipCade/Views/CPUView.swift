//
//  CPUView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct CPUView: View {
    @ObservedObject var game: Game

    var body: some View {
        VStack {
            // Registers on top of the CPU
            HStack {
                ForEach(0..<8, id: \.self) { index in
                    VStack {
                        Text("R\(index)")
                            .font(.caption)
                        Text(game.registers[index].toString())
                            .padding(5)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            //.border(Color.gray, width: 1)
                            .frame(width: 60)
                    }
                }
            }

            // CPU Shape
            ZStack {
                CPUShape()
                    .fill(Color.blue)
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("CPU")
                            .font(.title)
                            .foregroundColor(.white)
                    )

                // Connecting lines from registers to the CPU
//                ForEach(0..<8, id: \.self) { index in
//                    // Draw lines connecting registers to CPU
//                    ConnectionLine(startX: CGFloat(20 + (index * 30)), startY: -50, endX: 75, endY: 50)
//                        .stroke(Color.black, lineWidth: 2)
//                }
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

struct CPUShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect) // Draw a simple rectangle for the CPU
        return path
    }
}

struct ConnectionLine: Shape {
    var startX: CGFloat
    var startY: CGFloat
    var endX: CGFloat
    var endY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: endX, y: endY))
        return path
    }
}
