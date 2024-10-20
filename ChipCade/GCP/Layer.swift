//
//  Layer.swift
//  CHIPcade
//
//  Created by Markus Moenig on 20/10/24.
//

import Foundation

class Layer {
    
    // The layer index in the global array
    let index: Int
    
    var size: CGSize? = nil//CGSize(width: 32, height: 32)
    var isVisible: Bool = false
    
    // Initialization
    init(index: Int) {
        self.index = index
    }
    
    // setVisible
    func sVisibility(visible: Bool) {
        isVisible = visible
    }
}
