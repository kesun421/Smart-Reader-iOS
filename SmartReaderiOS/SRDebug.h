//
//  SRDebug.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#   define DebugLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DebugLog(...)
#endif

@interface SRDebug : NSObject

@end
