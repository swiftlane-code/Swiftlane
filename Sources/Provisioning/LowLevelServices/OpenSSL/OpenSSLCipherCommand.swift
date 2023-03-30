//

import Foundation

public enum OpenSSLCipherCommand: String {
    case aes_128_cbc = "aes-128-cbc"
    case aes_128_ecb = "aes-128-ecb"
    case aes_192_cbc = "aes-192-cbc"
    case aes_192_ecb = "aes-192-ecb"
    case aes_256_cbc = "aes-256-cbc"
    case aes_256_ecb = "aes-256-ecb"
    case base64
    case bf
    case bf_cbc = "bf-cbc"
    case bf_cfb = "bf-cfb"
    case bf_ecb = "bf-ecb"
    case bf_ofb = "bf-ofb"
    case camellia_128_cbc = "camellia-128-cbc"
    case camellia_128_ecb = "camellia-128-ecb"
    case camellia_192_cbc = "camellia-192-cbc"
    case camellia_192_ecb = "camellia-192-ecb"
    case camellia_256_cbc = "camellia-256-cbc"
    case camellia_256_ecb = "camellia-256-ecb"
    case cast
    case cast_cbc = "cast-cbc"
    case cast5_cbc = "cast5-cbc"
    case cast5_cfb = "cast5-cfb"
    case cast5_ecb = "cast5-ecb"
    case cast5_ofb = "cast5-ofb"
    case chacha
    case des
    case des_cbc = "des-cbc"
    case des_cfb = "des-cfb"
    case des_ecb = "des-ecb"
    case des_ede = "des-ede"
    case des_ede_cbc = "des-ede-cbc"
    case des_ede_cfb = "des-ede-cfb"
    case des_ede_ofb = "des-ede-ofb"
    case des_ede3 = "des-ede3"
    case des_ede3_cbc = "des-ede3-cbc"
    case des_ede3_cfb = "des-ede3-cfb"
    case des_ede3_ofb = "des-ede3-ofb"
    case des_ofb = "des-ofb"
    case des3
    case desx
    case rc2
    case rc2_40_cbc = "rc2-40-cbc"
    case rc2_64_cbc = "rc2-64-cbc"
    case rc2_cbc = "rc2-cbc"
    case rc2_cfb = "rc2-cfb"
    case rc2_ecb = "rc2-ecb"
    case rc2_ofb = "rc2-ofb"
    case rc4
    case rc4_40 = "rc4-40"
}
