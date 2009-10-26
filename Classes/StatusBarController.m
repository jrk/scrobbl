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

#import "StatusBarController.h"

@implementation StatusBarController
#include "NSLogOverride.h"

- (id) init {
	//Don't call [super init] , since it will complain that we can only have one app at a time.
	_responds = [super respondsToSelector:@selector(removeStatusBarImageNamed:)] && 
						[super respondsToSelector:@selector(addStatusBarImageNamed:removeOnExit:)] &&
	[[[NSUserDefaults standardUserDefaults] objectForKey:@"statusBarEnabled"] integerValue];
	NSLog(@"Status bar is %@enabled\n",[[[NSUserDefaults standardUserDefaults] objectForKey:@"statusBarEnabled"] integerValue]?@"":@"not ");
	if(!_responds)
		return nil;
	return self;
}

- (void) cleanStatusBar {
	_statusbarimage=nil;
	if(_responds) {
		//NSLog(@"Cleaning Status bar");
		[self removeStatusBarImageNamed:IMAGEFAILED];
		[self removeStatusBarImageNamed:IMAGESUCCESS];
		[self removeStatusBarImageNamed:IMAGEDEFAULT];
	}
}

- (void) defaultStatusBarImage {
	NSLog(@"Adding default status bar image\n");
	[self addStatusBarImageNamed: IMAGEDEFAULT removeOnExit: NO];
}

- (void) removeStatusBarImage {
	//NSLog(@"Removing status bar image named %@\n",_statusbarimage);
	if(_statusbarimage!=nil && _responds)
		[self removeStatusBarImageNamed:_statusbarimage];
	_statusbarimage=nil;
}

//override addStatusBarImageNamed so we only have one image at a time
- (void) addStatusBarImageNamed:(NSString*)image removeOnExit: (BOOL) remove {
	if(_statusbarimage!=nil && _responds)
		[self removeStatusBarImageNamed:_statusbarimage];
	_statusbarimage=image;
	if (_responds)
		[super addStatusBarImageNamed:image removeOnExit: remove];
}

- (void) refresh {
	if(_statusbarimage!=nil && _responds)
		[self addStatusBarImageNamed:_statusbarimage removeOnExit:FALSE];
}


- (void) addStatusBarImageNamed:(NSString*)image forTime:(NSTimeInterval)seconds{
	//NSLog(@"Adding status bar image named %@ for %.1f seconds\n",image,seconds);
	if([_statusTimer isValid]==YES)
		[_statusTimer invalidate]; //says we could invalidate at some later time, could this invalidate our new timer later?
	[_statusTimer release];
	[self addStatusBarImageNamed:image removeOnExit: NO];
	_statusTimer = [[NSTimer scheduledTimerWithTimeInterval:seconds
													 target:self
												   selector:@selector(defaultStatusBarImage)
												   userInfo:NULL
													repeats:NO] retain];
}
@end
