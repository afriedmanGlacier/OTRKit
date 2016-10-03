//
//  OTRUtility.m
//  Pods
//
//  Created by David Chiles on 10/3/16.
//
//

#import "OTRUtility.h"
#import "OTRErrorUtility.h"
#import "gcrypt.h"

@implementation OTRUtility

+ (NSData *)encryptAESGCMData:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError **)error {
    return [self AESGCMEncrypt:YES data:data key:key iv:iv error:error];
}

+ (NSData *)decryptAESGCMData:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError **)error {
    return [self AESGCMEncrypt:NO data:data key:key iv:iv error:error];
}

+ (NSData *)AESGCMEncrypt:(BOOL)encrypt data:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError **)error {
    
    assert([data length] != 0);
    assert([key length] != 0);
    assert([iv length] != 0);
    
    if ([data length] == 0 || [key length] == 0 || [iv length] == 0) {
        *error = [NSError errorWithDomain:kOTRKitErrorDomain code:8 userInfo:@{NSLocalizedDescriptionKey:@"All parameters need to be non-nil and have a length"}];
        return nil;
    }
    
    gcry_cipher_hd_t handle;
    gcry_error_t err = gcry_cipher_open(&handle,GCRY_CIPHER_AES128,GCRY_CIPHER_MODE_GCM,GCRY_CIPHER_SECURE);
    
    void (^errorHandleBlock)(gcry_cipher_hd_t, gcry_error_t) = ^void(gcry_cipher_hd_t handle, gcry_error_t err) {
        *error = [OTRErrorUtility errorForGPGError:err];
        gcry_cipher_close(handle);
    };
    
    if (err != 0) {
        errorHandleBlock(handle,err);
        return nil;
    }
    
    err = gcry_cipher_setkey(handle,key.bytes,key.length);
    if (err != 0) {
        errorHandleBlock(handle,err);
        return nil;
    }
    
    err = gcry_cipher_setiv(handle,iv.bytes,iv.length);
    if (err != 0) {
        errorHandleBlock(handle,err);
        return nil;
    }
    
    //size_t blockLength = gcry_cipher_get_algo_blklen(GCRY_CIPHER_AES128);
    NSMutableData *outData = [data mutableCopy];
    if (encrypt) {
        err = gcry_cipher_encrypt(handle, outData.bytes, outData.length, NULL, 0);
    } else {
        err = gcry_cipher_decrypt(handle, outData.bytes, outData.length, NULL, 0);
    }
    
    if (err != 0) {
        errorHandleBlock(handle,err);
        return nil;
    }
    
    gcry_cipher_close(handle);
    return [outData copy];
}

@end