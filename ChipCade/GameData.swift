//
//  GameData.swift
//  CHIPcade
//
//  Created by Markus Moenig on 3/10/24.
//

import SwiftUI

class GameData: Codable {
    
    var codeItems: [CodeItem] = []
    var spriteItems: [MemoryItem] = []
    var dataItems: [MemoryItem] = []
    var palette: [float4] = []

    enum CodingKeys: String, CodingKey {
        case codeItems, spriteItems, dataItems, palette
    }
    
    init() {
        self.codeItems = [CodeItem(name: "Init"), CodeItem(name: "Update")]
        self.spriteItems = []
        self.dataItems = [MemoryItem(name: "Data", length: 1024)]
        self.palette = GameData.defaultPalette()
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        codeItems = try container.decode([CodeItem].self, forKey: .codeItems)
        spriteItems = try container.decode([MemoryItem].self, forKey: .spriteItems)
        dataItems = try container.decode([MemoryItem].self, forKey: .dataItems)
        palette = try container.decode([float4].self, forKey: .palette)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(codeItems, forKey: .codeItems)
        try container.encode(spriteItems, forKey: .spriteItems)
        try container.encode(dataItems, forKey: .dataItems)
        try container.encode(palette, forKey: .palette)
    }
    
    // Get memory item.
    func getMemoryItem(name: String) -> MemoryItem? {
        if let foundItem = dataItems.first(where: { $0.name == name }) {
            return foundItem
        }

        return nil
    }
    
    // From https://lospec.com/palette-list/duel
    static func defaultPalette() -> [float4] {
        let hexColors = [
            "FF000000", "FF222323", "FF434549", "FF626871", "FF828b98", "FFa6aeba", "FFcdd2da", "FFf5f7fa",
            "FF625d54", "FF857565", "FF9e8c79", "FFaea189", "FFbbafa4", "FFccc3b1", "FFeadbc9", "FFfff3d6",
            "FF583126", "FF733d3b", "FF885041", "FF9a624c", "FFad6e51", "FFd58d6b", "FFfbaa84", "FFffce7f",
            "FF002735", "FF003850", "FF004d5e", "FF0b667f", "FF006f89", "FF328ca7", "FF24aed6", "FF88d6ff",
            "FF662b29", "FF94363a", "FFb64d46", "FFcd5e46", "FFe37840", "FFf99b4e", "FFffbc4e", "FFffe949",
            "FF282b4a", "FF3a4568", "FF615f84", "FF7a7799", "FF8690b2", "FF96b2d9", "FFc7d6ff", "FFc6ecff",
            "FF002219", "FF003221", "FF174a1b", "FF225918", "FF2f690c", "FF518822", "FF7da42d", "FFa6cc34",
            "FF181f2f", "FF23324d", "FF25466b", "FF366b8a", "FF318eb8", "FF41b2e3", "FF52d2ff", "FF74f5fd",
            "FF1a332c", "FF2f3f38", "FF385140", "FF325c40", "FF417455", "FF498960", "FF55b67d", "FF91daa1",
            "FF5e0711", "FF82211d", "FFb63c35", "FFe45c5f", "FFff7676", "FFff9ba8", "FFffbbc7", "FFffdbff",
            "FF2d3136", "FF48474d", "FF5b5c69", "FF73737f", "FF848795", "FFabaebe", "FFbac7db", "FFebf0f6",
            "FF3b303c", "FF5a3c45", "FF8a5258", "FFae6b60", "FFc7826c", "FFd89f75", "FFecc581", "FFfffaab",
            "FF31222a", "FF4a353c", "FF5e4646", "FF725a51", "FF7e6c54", "FF9e8a6e", "FFc0a588", "FFddbf9a",
            "FF2e1026", "FF49283d", "FF663659", "FF975475", "FFb96d91", "FFc178aa", "FFdb99bf", "FFf8c6da",
            "FF002e49", "FF004051", "FF005162", "FF006b6d", "FF008279", "FF00a087", "FF00bfa3", "FF00deda",
            "FF453125", "FF614a3c", "FF7e6144", "FF997951", "FFb29062", "FFcca96e", "FFe8cb82", "FFfbeaa3",
            "FF5f0926", "FF6e2434", "FF904647", "FFa76057", "FFbd7d64", "FFce9770", "FFedb67c", "FFedd493",
            "FF323558", "FF4a5280", "FF64659d", "FF7877c1", "FF8e8ce2", "FF9c9bef", "FFb8aeff", "FFdcd4ff",
            "FF431729", "FF712b3b", "FF9f3b52", "FFd94a69", "FFf85d80", "FFff7daf", "FFffa6c5", "FFffcdff",
            "FF49251c", "FF633432", "FF7c4b47", "FF98595a", "FFac6f6e", "FFc17e7a", "FFd28d7a", "FFe59a7c",
            "FF202900", "FF2f4f08", "FF495d00", "FF617308", "FF7c831e", "FF969a26", "FFb4aa33", "FFd0cc32",
            "FF622a00", "FF753b09", "FF854f12", "FF9e6520", "FFba882e", "FFd1aa39", "FFe8d24b", "FFfff64f",
            "FF26233d", "FF3b3855", "FF56506f", "FF75686e", "FF917a7b", "FFb39783", "FFcfaf8e", "FFfedfb1",
            "FF1d2c43", "FF2e3d47", "FF394d3c", "FF4c5f33", "FF58712c", "FF6b842d", "FF789e24", "FF7fbd39",
            "FF372423", "FF53393a", "FF784c49", "FF945d4f", "FFa96d58", "FFbf7e63", "FFd79374", "FFf4a380",
            "FF2d4b47", "FF47655a", "FF5b7b69", "FF71957d", "FF87ae8e", "FF8ac196", "FFa9d1c1", "FFe0faeb",
            "FF001b40", "FF03315f", "FF07487c", "FF105da2", "FF1476c0", "FF4097ea", "FF55b1f1", "FF6dccff",
            "FF554769", "FF765d73", "FF977488", "FFb98c93", "FFd5a39a", "FFebbd9d", "FFffd59b", "FFfdf786",
            "FF1d1d21", "FF3c3151", "FF584a7f", "FF7964ba", "FF9585f1", "FFa996ec", "FFbaabf7", "FFd1bdfe",
            "FF262450", "FF28335d", "FF2d3d72", "FF3d5083", "FF5165ae", "FF5274c5", "FF6c82c4", "FF8393c3",
            "FF492129", "FF5e414a", "FF77535b", "FF91606a", "FFad7984", "FFb58b94", "FFd4aeaa", "FFffe2cf",
            "FF721c03", "FF9c3327", "FFbf5a3e", "FFe98627", "FFffb108", "FFffcf05", "FFfff02b", "FFf7f4bf"
        ]

        var palette: [simd_float4] = []
        for hex in hexColors {
            palette.append(GameData.colorFromHex(hex))
        }
        return palette
    }

    static func randomColor() -> float4 {
        let red = Float.random(in: 0.0...1.0)
        let green = Float.random(in: 0.0...1.0)
        let blue = Float.random(in: 0.0...1.0)
        return simd_float4(red, green, blue, 1.0) // Alpha is always 1.0 (opaque)
    }
    
    // Convert a hex color string to simd_float4
    static func colorFromHex(_ hex: String) -> simd_float4 {
        var hexColor = hex
        if hexColor.hasPrefix("FF") {
            hexColor.removeFirst(2) // Remove the leading alpha (FF) if present
        }

        let red = Float(Int(hexColor.prefix(2), radix: 16) ?? 0) / 255.0
        let green = Float(Int(hexColor.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255.0
        let blue = Float(Int(hexColor.dropFirst(4).prefix(2), radix: 16) ?? 0) / 255.0
        let alpha: Float = 1.0 // Set alpha to 1.0 (fully opaque)

        return simd_float4(red, green, blue, alpha)
    }

    // Convert float4 to SwiftUI Color
    func color(at index: Int) -> Color {
        let rgba = palette[index]
        return Color(red: Double(rgba.x), green: Double(rgba.y), blue: Double(rgba.z), opacity: Double(rgba.w))
    }
    
    // Update the color at a specific index
    func updateColor(at index: Int, to newColor: Color) {
        guard let cgColor = newColor.cgColor else { return }
        let components = cgColor.components ?? [0, 0, 0, 1]
        palette[index] = simd_float4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
    }
}
