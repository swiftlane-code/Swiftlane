//

import Foundation
import Security

// MARK: - Private Extensions

private extension SecKey {
    static func create(from data: Data, isPrivate: Bool, keyType: KeychainService.KeyAlgorithm) throws -> SecKey {
        let attributes: [CFString: Any] = [
            kSecAttrKeyClass: isPrivate ? kSecAttrKeyClassPrivate : kSecAttrKeyClassPublic,
            kSecAttrKeyType: keyType.kSecAttrKeyType,
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
            print("Error: Problem in SecKeyCreateWithData()")
            debugPrint(error!.takeRetainedValue())
            throw error!.takeRetainedValue()
        }

        return secKey
    }

    func x963_or_PKCS1_Representation() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let cfdata = SecKeyCopyExternalRepresentation(self, &error) else {
            throw error!.takeRetainedValue()
        }
        return cfdata as Data
    }
}

// MARK: - KeychainService

public final class KeychainService {
    //	enum RSA {
    //		struct PrivateKey {
    //			let secKey: SecKey
//
    //			init(secKey: SecKey) {
    //				self.secKey = secKey
    //			}
//
    //			func x963Representation() throws -> Data {
    //				try secKey.x963Representation()
    //			}
    //		}
//
    //		struct PublicKey {
    //			let secKey: SecKey
//
    //			init(secKey: SecKey) {
    //				self.secKey = secKey
    //			}
//
    //			func x963Representation() throws -> Data {
    //				try secKey.x963Representation()
    //			}
    //		}
    //	}

    public enum KeyAlgorithm {
        case RSA

        var kSecAttrKeyType: CFString {
            switch self {
            case .RSA: return kSecAttrKeyTypeRSA
            }
        }
    }

    ///
    /// Be sure that you don’t generate multiple, identically tagged keys.
    /// These are difficult to tell apart during retrieval, unless they differ
    /// in some other, searchable characteristic. Instead, use a unique tag
    /// for each key generation operation, or delete old keys with a given tag
    /// using `SecItemDelete(_:)` before creating a new one with that tag.
    ///
    /// https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/generating_new_cryptographic_keys
    ///
    ///
    func createKeyPair(
        privateKeyName: String,
        publicKeyName: String,
        privateKeyIsPermanent: Bool,
        publicKeyIsPermanent: Bool,
        keyAlgorithm: KeyAlgorithm,
        keySizeInBits: Int
    ) throws -> (privateKey: SecKey, publicKey: SecKey) {
        let privateKeyAttr: [CFString: Any] = [
            kSecAttrLabel: privateKeyName,
            kSecAttrIsPermanent: privateKeyIsPermanent,
            kSecAttrApplicationTag: "\(#file).privateKey.\(Date())".data(using: .utf8)!,
            kSecClass: kSecClassKey,
            kSecReturnData: true,
        ]

        let publicKeyAttr: [CFString: Any] = [
            kSecAttrSubject: publicKeyName,
            kSecAttrIsPermanent: publicKeyIsPermanent,
            kSecAttrApplicationTag: "\(#file).publicKey.\(Date())".data(using: .utf8)!,
            kSecClass: kSecClassKey,
            kSecReturnData: true,
        ]

        let keyPairAttr: [CFString: Any] = [
            kSecAttrKeyType: keyAlgorithm.kSecAttrKeyType,
            kSecAttrKeySizeInBits: keySizeInBits,
            kSecPrivateKeyAttrs: privateKeyAttr,
            kSecPublicKeyAttrs: publicKeyAttr,
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyPairAttr as CFDictionary, &error) else {
            print("Error generating private key: \(String(describing: error!.takeRetainedValue()))")
            throw error!.takeRetainedValue()
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            print("Error generating public key: \(String(describing: error!.takeRetainedValue()))")
            throw error!.takeRetainedValue()
        }

        return (privateKey: privateKey, publicKey: publicKey)
    }

    func exportPEMRSAPrivateKey(_ rsaPrivateKey: SecKey) throws -> String {
        let data = try rsaPrivateKey.x963_or_PKCS1_Representation()
        let base64EncodedPKCS1 = data.base64EncodedString(
            options: [.lineLength64Characters, .endLineWithLineFeed]
        )

        let pemPrivateKey = [
            "-----BEGIN RSA PRIVATE KEY-----",
            base64EncodedPKCS1,
            "-----END RSA PRIVATE KEY-----",
        ].joined(separator: "\n")

        return pemPrivateKey
    }
}
