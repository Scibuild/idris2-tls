module Tests.Crypto

import Control.Monad.State
import Crypto.RSA
import Crypto.Random
import Crypto.Random.C
import Crypto.AES.Common
import Crypto.AES.Small
import Crypto.AES.Big
import Crypto.Hash
import Data.Vect
import Data.List1
import Utils.Bytes
import Utils.Misc

test_chacha : HasIO m => m ()
test_chacha = do
  drg <- new_chacha12_drg
  let a = evalState drg (random_bytes 1024)
  putStrLn $ show a

test_rsa : HasIO m => m Integer
test_rsa = do
  (pk, sk) <- generate_key_pair 1024
  let m = 42069
  let c = rsa_encrypt pk m
  rsa_decrypt_blinded sk c

test_aes_128_key : Vect 16 Bits8
test_aes_128_key =
  [ 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c ]

test_aes_192_key : Vect 24 Bits8
test_aes_192_key =
  [ 0x8e, 0x73, 0xb0, 0xf7, 0xda, 0x0e, 0x64, 0x52, 0xc8, 0x10, 0xf3, 0x2b, 0x80, 0x90, 0x79, 0xe5
  , 0x62, 0xf8, 0xea, 0xd2, 0x52, 0x2c, 0x6b, 0x7b ]

test_aes_256_key : Vect 32 Bits8
test_aes_256_key =
  [ 0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe, 0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81
  , 0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7, 0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4 ]

test_aes_plaintext : Vect 16 Bits8
test_aes_plaintext =
  [ 0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a ]

test_aes_128_ciphertext : Vect 16 Bits8
test_aes_128_ciphertext =
  Small.encrypt_block AES128 test_aes_128_key test_aes_plaintext

test_aes_192_ciphertext : Vect 16 Bits8
test_aes_192_ciphertext =
  Small.encrypt_block AES192 test_aes_192_key test_aes_plaintext

test_aes_256_ciphertext : Vect 16 Bits8
test_aes_256_ciphertext =
  Small.encrypt_block AES256 test_aes_256_key test_aes_plaintext

test_aes_big_128_ciphertext : Vect 16 Bits8
test_aes_big_128_ciphertext =
  Big.encrypt_block AES128 test_aes_128_key test_aes_plaintext

test_aes_big_192_ciphertext : Vect 16 Bits8
test_aes_big_192_ciphertext =
  Big.encrypt_block AES192 test_aes_192_key test_aes_plaintext

test_aes_big_256_ciphertext : Vect 16 Bits8
test_aes_big_256_ciphertext =
  Big.encrypt_block AES256 test_aes_256_key test_aes_plaintext

||| test case where padding first bit would be set
test_rsa_pss : Maybe ()
test_rsa_pss =
  emsa_pss_verify {algo=Sha256}
    (mgf1 {algo=Sha256})
    32
    [ 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
    , 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
    , 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x54, 0x4c
    , 0x53, 0x20, 0x31, 0x2e, 0x33, 0x2c, 0x20, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x20, 0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63
    , 0x61, 0x74, 0x65, 0x56, 0x65, 0x72, 0x69, 0x66, 0x79, 0x00, 0x8b, 0xea, 0x0f, 0x13, 0xa1, 0xa0, 0xa2, 0x30, 0xfc, 0x94, 0xe4, 0x21
    , 0xf1, 0x21, 0x3a, 0x4e, 0x00, 0xed, 0x45, 0x39, 0xe6, 0x49, 0x04, 0xfe, 0x98, 0x55, 0x0c, 0x97, 0xa0, 0xa3, 0xaf, 0x34, 0x64, 0xcf
    , 0xa0, 0x35, 0x36, 0xcf, 0x60, 0x0a, 0x2f, 0x1e, 0x04, 0xe7, 0x0d, 0xe6, 0x04, 0x6d ]
    (0x18 ::: [ 0xf9, 0x15, 0x8c, 0x76, 0x0d, 0x2d, 0x7f, 0x57, 0x36, 0x01, 0x8e, 0x89, 0x33, 0x92, 0xdc, 0x04, 0xb2, 0x02, 0x46, 0x30, 0x8b
    , 0x06, 0xc8, 0x65, 0x94, 0x71, 0xac, 0x3c, 0x6f, 0xe2, 0x71, 0x2b, 0x11, 0xe6, 0x4c, 0x7d, 0x11, 0x1f, 0x5a, 0x82, 0x20, 0x3c, 0x7c
    , 0x29, 0x83, 0x43, 0x1a, 0xcf, 0xd8, 0xc4, 0x4c, 0xad, 0xfc, 0x78, 0xf0, 0xef, 0x16, 0x1b, 0x24, 0xbf, 0xa5, 0x16, 0x8a, 0x47, 0xe7
    , 0x1d, 0x60, 0xd2, 0x6b, 0x08, 0xfa, 0x37, 0xdc, 0x76, 0x42, 0x88, 0x7c, 0xa5, 0x91, 0x97, 0x69, 0xa7, 0xd5, 0x50, 0x66, 0x09, 0xb6
    , 0x8a, 0x12, 0x76, 0x6e, 0xd1, 0xa6, 0xb0, 0x9e, 0x6d, 0xe6, 0xf2, 0x8a, 0x79, 0x4c, 0x68, 0x29, 0x52, 0xdb, 0x53, 0x36, 0x9b, 0x49
    , 0xed, 0x21, 0xf2, 0x48, 0x1d, 0x0e, 0x9f, 0x92, 0x23, 0x96, 0x0b, 0xc4, 0x47, 0x94, 0xb5, 0xec, 0x13, 0x40, 0x75, 0xde, 0x14, 0x9c
    , 0xa6, 0xa7, 0x2c, 0x9f, 0xbf, 0xe3, 0x94, 0xde, 0xeb, 0x49, 0xdc, 0x6a, 0xdc, 0x30, 0xa3, 0x0c, 0xf5, 0x2e, 0xe6, 0x14, 0x3f, 0xe2
    , 0x98, 0x27, 0x14, 0x8d, 0x21, 0x92, 0x20, 0xaa, 0xfb, 0x4e, 0x08, 0xa5, 0xd4, 0x7c, 0x8a, 0xf2, 0xed, 0x75, 0xa7, 0x6c, 0x01, 0xa4
    , 0x18, 0x4c, 0x58, 0x12, 0x10, 0xff, 0x2d, 0xc5, 0x0f, 0x8d, 0xe5, 0xab, 0x56, 0xa9, 0x81, 0x7c, 0x87, 0x4d, 0x19, 0xa4, 0x37, 0x96
    , 0x5d, 0x82, 0x84, 0xaa, 0x44, 0xc0, 0x7f, 0x4f, 0x39, 0xf4, 0x5d, 0x0d, 0xeb, 0xda, 0x3e, 0x2c, 0xd3, 0xaf, 0xe9, 0xf5, 0x24, 0x1e
    , 0x38, 0xb7, 0x35, 0x09, 0xda, 0x62, 0xc1, 0x3b, 0x89, 0x5c, 0xa9, 0xcc, 0x76, 0xe6, 0xed, 0x7f, 0xc6, 0xe0, 0x3a, 0x73, 0x94, 0x33
    , 0xca, 0x60, 0xf0, 0x15, 0xc7, 0x79, 0x62, 0x69, 0x68, 0x4d, 0xfd, 0x49, 0x98, 0xbc ])
    2047
