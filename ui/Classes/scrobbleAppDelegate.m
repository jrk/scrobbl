//
//  scrobbleAppDelegate.m
//  scrobble
//
//  Created by Tony Hoyle on 16/08/2008.
//  Licensed under the GNU GPL v2
//

#import "scrobbleAppDelegate.h"
#import "RootViewController.h"

@implementation scrobbleAppDelegate

@synthesize window;
@synthesize rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[window addSubview:[rootViewController view]];
	[window makeKeyAndVisible];
}


- (void)dealloc {
	[rootViewController release];
	[window release];
	[super dealloc];
}

@end
