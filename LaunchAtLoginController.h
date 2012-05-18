//
//  LaunchAtLoginController.h
//
//  Created by Ben Clark-Robinson on 24/03/10.
//  Copyright 2010 Mozketo. All rights reserved.
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

#import <Cocoa/Cocoa.h>


@interface LaunchAtLoginController : NSObject {
    LSSharedFileListRef loginItems;
}

@property BOOL launchAtLogin;

- (BOOL)willLaunchAtLogin:(NSURL *)itemUrl;
- (BOOL)willLaunchHiddenAtLogin: (NSURL*)itemURL;

- (void)setLaunchAtLogin:(BOOL)enabled;
- (void)setLaunchAtLogin:(BOOL)enabled hidden:(BOOL)hidden;
- (void)setLaunchAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;
- (void)setLaunchAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled hidden:(BOOL)hidden;

@end
