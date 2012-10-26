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

static NSString *const StartAtLoginKey = @"launchAtLogin";

@interface LaunchAtLoginController ()
@property(assign) LSSharedFileListRef loginItems;
@end

@implementation LaunchAtLoginController
@synthesize loginItems;

void sharedFileListDidChange(LSSharedFileListRef inList, void *context)
{
    LaunchAtLoginController *self = (id) context;
    [self willChangeValueForKey:StartAtLoginKey];
    [self didChangeValueForKey:StartAtLoginKey];
}

- (id) init
{
    [super init];
    loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    LSSharedFileListAddObserver(loginItems, CFRunLoopGetMain(),
								(CFStringRef)NSDefaultRunLoopMode, sharedFileListDidChange, self);
    return self;
}

- (void) dealloc
{
    LSSharedFileListRemoveObserver(loginItems, CFRunLoopGetMain(),
								   (CFStringRef)NSDefaultRunLoopMode, sharedFileListDidChange, self);
    CFRelease(loginItems);
    [super dealloc];
}

- (NSURL *)appURL {
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)launchAtLogin {
    return [self willLaunchAtLogin:[self appURL]];
}

- (LSSharedFileListItemRef) findItemWithURL: (NSURL*) wantedURL inFileList: (LSSharedFileListRef) fileList
{
    if (wantedURL == NULL || fileList == NULL)
        return NULL;
	
	// Get the URL's file attributes. That includes the NSFileSystemFileNumber.
	// comparing the file number is better than comparing URLs
	// because it doesn't have to deal with case sensitivity
	
	NSDictionary* wantedAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: [(NSURL*)wantedURL path] error: nil];
    NSArray *listSnapshot = [NSMakeCollectable(LSSharedFileListCopySnapshot(fileList, NULL)) autorelease];
    for (id itemObject in listSnapshot)
	{
        LSSharedFileListItemRef item = (LSSharedFileListItemRef) itemObject;
        UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef currentItemURL = NULL;
        LSSharedFileListItemResolve(item, resolutionFlags, &currentItemURL, NULL);
		
		NSDictionary* currentAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[(NSURL*)currentItemURL path] error:nil];
        
		if (currentAttributes && [currentAttributes isEqual: wantedAttributes])
		{
			CFRelease(currentItemURL);
            return item;
        }
        if (currentItemURL)
            CFRelease(currentItemURL);
    }
	
    return NULL;
}

- (LSSharedFileListItemRef)findItemWithURL:(NSURL*)wantedURL 
{
	return [self findItemWithURL:wantedURL inFileList:self.loginItems];
}

- (BOOL) willLaunchAtLogin: (NSURL*) itemURL
{
    return !![self findItemWithURL: itemURL];
}

- (BOOL)willLaunchHiddenAtLogin: (NSURL*)itemURL
{
	LSSharedFileListItemRef item = [self findItemWithURL:itemURL];
	if (item)
	{
		NSNumber* number = LSSharedFileListItemCopyProperty(item, kLSSharedFileListLoginItemHidden);
		if (number)
		{
			return [number boolValue];
		}
	}
	return NO;
}

- (void)setLaunchAtLogin:(BOOL)enabled 
{
    [self willChangeValueForKey:@"startAtLogin"];
    [self setLaunchAtLogin:[self appURL] enabled:enabled];
    [self didChangeValueForKey:@"startAtLogin"];
}

- (void)setLaunchAtLogin:(BOOL)enabled hidden:(BOOL)hidden 
{
	[self willChangeValueForKey:@"startAtLogin"];
    [self setLaunchAtLogin:[self appURL] enabled:enabled hidden:hidden];
    [self didChangeValueForKey:@"startAtLogin"];
}

- (void)setLaunchAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled 
{
    [self setLaunchAtLogin:itemURL enabled:enabled hidden:NO];
}

- (void)setLaunchAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled hidden:(BOOL)hidden 
{
    LSSharedFileListItemRef existingItem = [self findItemWithURL:itemURL inFileList:loginItems];
	
	if (enabled && (existingItem == NULL)) 
	{
		if(!hidden) 
		{
			LSSharedFileListInsertItemURL(self.loginItems, kLSSharedFileListItemBeforeFirst,
										  NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
		}
		else 
		{
			NSDictionary *setProperties =
			[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:hidden]
										forKey:(id)kLSSharedFileListLoginItemHidden];
			LSSharedFileListInsertItemURL(self.loginItems, kLSSharedFileListItemBeforeFirst,
										  NULL, NULL, (CFURLRef)itemURL, (CFDictionaryRef)setProperties, NULL);
		}
		
	}
	else if (!enabled && (existingItem != NULL))
	{
		LSSharedFileListItemRemove(self.loginItems, existingItem);
	}	
}

@end

