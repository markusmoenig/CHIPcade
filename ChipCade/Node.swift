//
//  Node.swift
//  CHIPcade
//
//  Created by Markus Moenig on 22/11/24.
//

import SwiftUI

enum NodeType {
    case code
    case image
}

struct Node: Identifiable {
    let id = UUID()
    var name: String
    var type: NodeType
    var isFolder: Bool = false
    var children: [Node]?
    
    init(type: NodeType, name: String) {
        self.type = type
        self.name = name
    }
}
