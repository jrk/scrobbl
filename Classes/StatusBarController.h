/* StatusBarController.m - Scrobbler Daemon for Apple iPhone
 * Copyright (C) 2009 Chris W <iphonescrobble@gmail.com>
 *
 * This file is part of Scrobbl.
 *
 * MobileScrobbler is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3
 * as published by the Free Software Foundation.
 *
 * MobileScrobbler is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define IMAGEDEFAULT @"MobileScrobbler"
#define	IMAGESUCCESS @"GreenScrobbler"
#define	IMAGEFAILED @"RedScrobbler"

@interface UIApplication(PrivateAPI)
-(void)addStatusBarImageNamed:(NSString*)fp8 removeOnExit:(BOOL)remove;
-(void)removeStatusBarImageNamed:(NSString*)fp8;
@end

@interface StatusBarController : UIApplication {
	NSTimer* _statusTimer;
	NSString* _statusbarimage;
	BOOL	_responds;
}

- (void) defaultStatusBarImage;
- (void) cleanStatusBar;
- (void) removeStatusBarImage;
- (void) addStatusBarImageNamed:(NSString*)image removeOnExit: (BOOL) remove;
- (void) addStatusBarImageNamed:(NSString*)image forTime:(NSTimeInterval)seconds;	
- (void) refresh;
@end
