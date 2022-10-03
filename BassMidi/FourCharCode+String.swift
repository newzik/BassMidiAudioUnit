//
//  FourCharCode+String.swift
//  MetronomeAudioUnitFramework
//
//  Created by Pierre Mardon on 10/03/2022.
//  From https://gist.github.com/patrickjuchli/d1b07f97e0ea1da5db09
import Foundation

/**
 Set FourCharCode/OSType using a String.

 Examples:
 let test: FourCharCode = "420v"
 let test2 = FourCharCode("420f")
 print(test.string, test2.string)
*/
extension FourCharCode: ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        var code: FourCharCode = 0
        // Value has to consist of 4 printable ASCII characters, e.g. '420v'.
        // Note: This implementation does not enforce printable range (32-126)
        if value.count == 4 && value.utf8.count == 4 {
            for byte in value.utf8 {
                code = code << 8 + FourCharCode(byte)
            }
        }
        else {
            print("FourCharCode: Can't initialize with '\(value)', only printable ASCII allowed. Setting to '????'.")
            code = 0x3F3F3F3F // = '????'
        }
        self = code
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = FourCharCode(stringLiteral: value)
    }

    public init(unicodeScalarLiteral value: String) {
        self = FourCharCode(stringLiteral: value)
    }

    public init(_ value: String) {
        self = FourCharCode(stringLiteral: value)
    }
}
