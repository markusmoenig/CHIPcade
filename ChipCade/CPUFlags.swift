//
//  CPUFlags.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/10/24.
//

class CPUFlags {
    private(set) var zeroFlag: Bool = false  // Zero Flag (ZF)
    private(set) var carryFlag: Bool = false  // Carry Flag (CF)
    private(set) var overflowFlag: Bool = false  // Overflow Flag (OF)
    private(set) var negativeFlag: Bool = false  // Negative Flag (NF)

    // Set specific flags
    func setZeroFlag(_ value: Bool) {
        zeroFlag = value
    }

    func setCarryFlag(_ value: Bool) {
        carryFlag = value
    }

    func setOverflowFlag(_ value: Bool) {
        overflowFlag = value
    }

    func setNegativeFlag(_ value: Bool) {
        negativeFlag = value
    }

    // Clear all flags
    func clearFlags() {
        zeroFlag = false
        carryFlag = false
        overflowFlag = false
        negativeFlag = false
    }

    // Display the flags as 0 or 1
    func displayFlags() -> String {
        let zf = zeroFlag ? "1" : "0"
        let cf = carryFlag ? "1" : "0"
        let of = overflowFlag ? "1" : "0"
        let nf = negativeFlag ? "1" : "0"
        return "ZF: \(zf)  CF: \(cf)  OF: \(of)  NF: \(nf)"
    }
}
