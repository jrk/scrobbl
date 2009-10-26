/* Player.m - Scrobbler Daemon for Apple iPhone
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
#import <MediaPlayer/MediaPlayer.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>

@interface Player : NSObject {
	pid_t oldPid;
}
-(BOOL) playerRunning;
-(BOOL) playerRunning: (pid_t)testpid;
-(BOOL)isPlaying;
-(NSDictionary *)trackInfo;
-(int)trackPosition;
-(NSMutableDictionary *)asTrack:(MPMediaItem*)item;
@end
