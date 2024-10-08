//
//  ImageGroup.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import Foundation
import MetalKit

class ImageGroup {

    var name: String
    var images: [MTLTexture] = []
    
    init(name: String) {
        self.name = name
    }
}
