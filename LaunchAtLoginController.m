//
//  LaunchAtLoginController.m
//
//  Created by Ben Clark-Robinson on 24/03/10.
//  Copyright 2010 Ben Clark-Robinson. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//	a copy of this software and associated documentation files (the
//																'Software'), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "LaunchAtLoginController.h"


@implementation LaunchAtLoginController

- (NSURL *)appURL {
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)launchAtLogin {
    return [self willLaunchAtLogin:[self appURL]];
}

- (BOOL)willLaunchAtLogin:(NSURL *)itemURL {
    Boolean foundIt=false;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
            if (err == noErr) {
                foundIt = CFEqual(URL, itemURL);
                CFRelease(URL);
				
                if (foundIt)
                    break;
            }
        }
        CFRelease(loginItems);
    }
    return (BOOL)foundIt;
}

- (void)setLaunchAtLogin:(BOOL)enabled {
    [self willChangeValueForKey:@"startAtLogin"];
    [self setLaunchAtLogin:[self appURL] enabled:enabled];
    [self didChangeValueForKey:@"startAtLogin"];
}

- (void)setLaunchAtLogin:(BOOL)enabled hidden:(BOOL)hidden {
    [self willChangeValueForKey:@"startAtLogin"];
    [self setLaunchAtLogin:[self appURL] enabled:enabled hidden:hidden];
    [self didChangeValueForKey:@"startAtLogin"];
}

- (void)setLaunchAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled {
    [self setLaunchAtLogin:itemURL enabled:enabled hidden:NO];
}

- (void)setLaunchAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled hidden:(BOOL)hidden {
    LSSharedFileListItemRef existingItem = NULL;
	
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
            if (err == noErr) {
                Boolean foundIt = CFEqual(URL, itemURL);
                CFRelease(URL);
				
                if (foundIt) {
                    existingItem = item;
                    break;
                }
            }
        }
        
        if (enabled && (existingItem == NULL)) {
            if(!hidden) {
                LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
                                              NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
            }
            else {
                NSDictionary *setProperties =
                [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:hidden]
                                            forKey:(id)kLSSharedFileListLoginItemHidden];
                LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
                                              NULL, NULL, (CFURLRef)itemURL, (CFDictionaryRef)setProperties, NULL);
            }
			
        } else if (!enabled && (existingItem != NULL))
            LSSharedFileListItemRemove(loginItems, existingItem);
		
        CFRelease(loginItems);
    } 
}

@end
