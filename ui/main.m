//
//  main.m
//  scrobble
//
//  Created by Tony Hoyle on 16/08/2008.
//  Licensed under the GNU GPL v2
//

#import <UIKit/UIKit.h>
int uid;
int main(int argc, char *argv[]) {
	uid = getuid();
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, nil);
	[pool release];
	return retVal;
}
