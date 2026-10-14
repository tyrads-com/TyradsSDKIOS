import Foundation
import CryptoKit

final class TyradsAESEncrypt {
    private let key: SymmetricKey

    init(encryptionKey: String) throws {
        let keyData = Data(encryptionKey.utf8)
        guard keyData.count == 32 else {
            throw AESError.invalidKeyLength
        }
        key = SymmetricKey(data: keyData)
    }

    func encryptAESGCM(_ payload: [String: Any]) throws -> [String: Any] {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw AESError.encodingFailed
        }
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        guard let combined = sealedBox.combined else {
            throw AESError.sealFailed
        }
        // Extract nonce (first 12 bytes) and tag (last 16 bytes) from combined
        let nonce = combined.prefix(12)
        let tag = sealedBox.tag
        let cipherText = sealedBox.ciphertext

        return [
            "val": cipherText.base64EncodedString(),
            "vec": Data(nonce).base64EncodedString(),
            "tag": tag.base64EncodedString()
        ]
    }

    func decryptAESGCM(_ payload: [String: Any]) throws -> String {
        guard
            let valStr = payload["val"] as? String,
            let vecStr = payload["vec"] as? String,
            let tagStr = payload["tag"] as? String,
            let cipherText = Data(base64Encoded: valStr),
            let nonceData = Data(base64Encoded: vecStr),
            let tagData = Data(base64Encoded: tagStr)
        else {
            throw AESError.decodingFailed
        }

        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: cipherText, tag: tagData)
        let plainData = try AES.GCM.open(sealedBox, using: key)
        return String(data: plainData, encoding: .utf8) ?? ""
    }

    enum AESError: Error {
        case invalidKeyLength
        case encodingFailed
        case sealFailed
        case decodingFailed
    }
}
