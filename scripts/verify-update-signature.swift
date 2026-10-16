// Checks an update's EdDSA signature against the public key built into the app, so a release
// signed with any other key fails before it is published instead of on users' Macs.
// Usage: swift scripts/verify-update-signature.swift <SUPublicEDKey> <signature> <file>
import CryptoKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4,
    let publicKeyData = Data(base64Encoded: arguments[1]),
    let signature = Data(base64Encoded: arguments[2])
else {
    FileHandle.standardError.write(Data("usage: verify-update-signature.swift <public-key> <signature> <file>\n".utf8))
    exit(64)
}

let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
let file = try Data(contentsOf: URL(filePath: arguments[3]))

guard publicKey.isValidSignature(signature, for: file) else {
    FileHandle.standardError.write(Data("error: the signature doesn't match the app's SUPublicEDKey\n".utf8))
    exit(1)
}
print("Signature matches the app's public key")
