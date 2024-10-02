//
//  Math.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import simd

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

let π = Float.pi

extension Float {
    var radiansToDegrees: Float {
        (self / π) * 180
    }
    var degreesToRadians: Float {
        (self / 180) * π
    }
}

extension Double {
    var radiansToDegrees: Double {
        (self / Double.pi) * 180
    }
    var degreesToRadians: Double {
        (self / 180) * Double.pi
    }
}

// To be able to expose Float4s in a public enum
public struct GCPFloat4 {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float
    
    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(simd: SIMD4<Float>) {
        self.x = simd.x
        self.y = simd.y
        self.z = simd.z
        self.w = simd.w
    }
    
    public var simd: SIMD4<Float> {
        return float4(x, y, z, w)
    }
}
