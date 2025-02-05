//
//  TexturePicker.swift
//  CHIPcade
//
//  Created by Markus Moenig on 25/11/24.
//

import SwiftUI

struct TexturePicker: View {
    @ObservedObject var gameData: GameData
//    @Binding var selectedImage: (Int, Int)? // (Group ID, Index) of the current selection
//    var onSelect: (Int, Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(gameData.imageGroupItems, id: \.id) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Display group name
                        Text(group.name)
                            .font(.headline)
                            .padding(.leading)

                        // Display items in a grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 1)], spacing: 1) {
                            ForEach(group.images.indices, id: \.self) { index in
                                if let nsImage = NSImage(data: group.images[index]) {
                                    ZStack {
                                        // Image
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 48, height: 48)

                                        // Highlight selected image
//                                        if let selected = selectedImage, selected == (group.intId, index) {
//                                            Rectangle()
//                                                .stroke(Color.accentColor, lineWidth: 2)
//                                        }
                                    }
                                    .onTapGesture {
//                                        // Update selection and call the callback
//                                        selectedImage = (group.intId, index)
//                                        onSelect(group.intId, index)
                                        print(index)
                                    }
                                }
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical)
                }
            }
            .padding()
        }
    }
}
