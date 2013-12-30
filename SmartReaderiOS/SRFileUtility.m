//
//  SRFileUtilities.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRFileUtility.h"

@interface SRFileUtility ()

@property (nonatomic) NSFileManager *fileManager;

@end

@implementation SRFileUtility

+ (instancetype)sharedUtility
{
    static SRFileUtility *_sharedUtility = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedUtility = [SRFileUtility new];
    });
    
    return _sharedUtility;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.fileManager = [NSFileManager defaultManager];
        _documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    }
    
    return self;
}

- (NSString *)documentPathForFile:(NSString *)fileName
{
    return [self.documentsPath stringByAppendingPathComponent:fileName];
}

- (NSString *)documentSizeForFile:(NSString *)fileName
{
    NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:[self documentPathForFile:fileName] error:nil];
    
    return [NSString stringWithFormat:@"%llu", fileAttributes.fileSize];
}

- (BOOL)removeDocumentFile:(NSString *)fileName
{
    return [self.fileManager removeItemAtPath:[self.documentsPath stringByAppendingPathComponent:fileName] error:nil];
}

@end
