//
//  LaunchAtLoginController.m
//
//  Created by Ben Clark-Robinson on 24/03/10.
//  Copyright 2010 Mozketo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the ‘Software’),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "LaunchAtLoginController.h"

@implementation LaunchAtLoginController

- (NSURL*) appURL {
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL) launchAtLogin {
    return [self willLaunchAtLogin:[self appURL]];
}

- (LSSharedFileListItemRef) findItemWithURL: (NSURL*) wantedURL inFileList: (LSSharedFileListRef) fileList
{
    if (wantedURL == NULL || fileList == NULL)
        return NULL;

    NSArray *listSnapshot = [NSMakeCollectable(LSSharedFileListCopySnapshot(fileList, NULL)) autorelease];
    for (id itemObject in listSnapshot) {
        LSSharedFileListItemRef item = (LSSharedFileListItemRef) itemObject;
        UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef currentItemURL = NULL;
        LSSharedFileListItemResolve(item, resolutionFlags, &currentItemURL, NULL);
        if (currentItemURL && CFEqual(currentItemURL, wantedURL)) {
            CFRelease(currentItemURL);
            return item;
        }
        CFRelease(currentItemURL);
    }

    return NULL;
}

- (BOOL) willLaunchAtLogin: (NSURL*) itemURL
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    BOOL itemExists = !![self findItemWithURL:itemURL inFileList:loginItems];
    CFRelease(loginItems);
    return itemExists;
}

- (void) setLaunchAtLogin: (BOOL) enabled
{
    [self willChangeValueForKey:@"startAtLogin"];
    [self setLaunchAtLogin:[self appURL] enabled:enabled];
    [self didChangeValueForKey:@"startAtLogin"];
}

- (void) setLaunchAtLogin: (NSURL*) itemURL enabled: (BOOL) enabled
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    LSSharedFileListItemRef appItem = [self findItemWithURL:itemURL inFileList:loginItems];
    if (enabled && !appItem) {
        LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
            NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
    } else if (!enabled && appItem)
        LSSharedFileListItemRemove(loginItems, appItem);
    CFRelease(loginItems);
}

@end
