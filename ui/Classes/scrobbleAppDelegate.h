//
//  scrobbleAppDelegate.h
//  scrobble
//
//  Created by Tony Hoyle on 16/08/2008.
//  Licensed under the GNU GPL v2
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface scrobbleAppDelegate : NSObject <UIApplicationDelegate> {

	IBOutlet UIWindow *window;
	IBOutlet RootViewController *rootViewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) RootViewController *rootViewController;

@end

