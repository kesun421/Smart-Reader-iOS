//
//  SRFileUtilities.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRFileUtility : NSObject

+ (instancetype)sharedUtility;

- (NSString *)documentPathForFile:(NSString *)fileName;
/** Returns number of bytes that the file utilizes on disk. */
- (NSString *)documentSizeForFile:(NSString *)fileName;
- (BOOL)removeDocumentFile:(NSString *)fileName;

@property (nonatomic, readonly) NSString *documentsPath;

@end