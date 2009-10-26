//
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

#import "Player.h"
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#import "Scrobbler.h"

@implementation Player
#include "NSLogOverride.h"

- (id) init {
	oldPid = -1;
	return [super init]; 
}

- (void)dealloc {
	[[MPMusicPlayerController iPodMusicPlayer] endGeneratingPlaybackNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(BOOL)isPlaying {
	//Only call [MPMusicPlayerController iPodMusicPlayer] if there's a player running.
	//Should fix issue identified by SporTech where player would randomly start up
	//First try the old pid, should be quicker than querying the entire proccess list
	if ([self playerRunning:oldPid]) {
		return ([[MPMusicPlayerController iPodMusicPlayer] playbackState]==MPMusicPlaybackStatePlaying);
	} else {
		if ([self playerRunning])
		{
			BOOL ret = ([[MPMusicPlayerController iPodMusicPlayer] playbackState]==MPMusicPlaybackStatePlaying);
			return ret;
		}
		return FALSE;
	}
}

- (void)_trackDidChange:(NSNotification *)notification {
	NSLog(@"Player got track changed\n");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:TRACKDIDCHANGE object:nil]];
}


//Adapted from Nate True's dock application:
-(BOOL) playerRunning: (pid_t)testpid {
	uint32_t	    i;
	size_t			length;
	int32_t			err;
	struct kinfo_proc      kp;
	int				mib[ 4 ] = { CTL_KERN, KERN_PROC, KERN_PROC_PID };
	
	mib[3]=testpid;
	length = sizeof(kp);	
	for ( i = 0; i < 60; ++i ) {
		// in the event of inordinate system load, transient sysctl() failures are
		// possible.  retry for up to one minute if necessary.
		if ( ! ( err = sysctl( mib, 4, &kp, &length, NULL, 0 ) ) ) break;
		NSLog(@"Got sysctl() failure %i testing MobileMusicPlayer pid.\n",errno);
		sleep( 1 );
	}	
	
	if (err) 
		return -1;
	
	if (!strncasecmp(kp.kp_proc.p_comm,"MobileMusicPlayer",MAXCOMLEN))
		return TRUE;
	else
		return FALSE;
}

//From Nate True's dock application:
-(BOOL) playerRunning {
	uint32_t	    i;
	size_t			length;
	int32_t			err, count;
	struct kinfo_proc	   *process_buffer;
	struct kinfo_proc      *kp;
	int				mib[ 3 ] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
	pid_t           spring_pid;
	int             loop;
	
	spring_pid = -1;
	
	sysctl( mib, 3, NULL, &length, NULL, 0 );
	
	if (length == 0)
		return -1;
	
	process_buffer = (struct kinfo_proc *)malloc(length);
	
	for ( i = 0; i < 60; ++i ) {
		// in the event of inordinate system load, transient sysctl() failures are
		// possible.  retry for up to one minute if necessary.
		if ( ! ( err = sysctl( mib, 3, process_buffer, &length, NULL, 0 ) ) ) break;
		NSLog(@"Got sysctl() failure getting MobileMusicPlayer pid.\n");
		sleep( 1 );
	}	
	
	if (err) {
		free(process_buffer);
		return -1;
	}
	
	count = length / sizeof(struct kinfo_proc);
	
	kp = process_buffer;
	
	for (loop = 0; (loop < count) && (spring_pid == -1); loop++) {
		if (!strncasecmp(kp->kp_proc.p_comm,"MobileMusicPlayer",MAXCOMLEN)) { //
			spring_pid = kp->kp_proc.p_pid;
		}
		kp++;
	}
	free(process_buffer);
	if (spring_pid != oldPid && spring_pid != -1) {
		NSLog(@"Found player at pid: %ld\n",(long)spring_pid);
	}
	oldPid=spring_pid;
	return (spring_pid != -1);
}


-(NSDictionary *)trackInfo {
	MPMusicPlayerController *iPodPlayer=[MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *nowPlayingItem = [iPodPlayer nowPlayingItem]; 
	BOOL podcastDontScrobble = ((([[nowPlayingItem valueForProperty:MPMediaItemPropertyMediaType] longValue] & (MPMediaTypePodcast | MPMediaTypeAudioBook)) != 0) && 
								[[[NSUserDefaults standardUserDefaults] objectForKey:@"scrobblePodcasts"] integerValue] == 0);
	if(nowPlayingItem != nil && !podcastDontScrobble) {
		NSMutableDictionary *track = [self asTrack:nowPlayingItem];
		NSNumber *startTime =  [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - [iPodPlayer currentPlaybackTime]];
		[track setValue:[NSString stringWithFormat:@"%qu",[startTime unsignedLongLongValue]] forKey:@"startTime"];
		return track;
	} else {
		return nil;
	}	
}


-(int)trackPosition {
	return [[MPMusicPlayerController iPodMusicPlayer] currentPlaybackTime];
}

-(NSMutableDictionary *)asTrack:(MPMediaItem*)item {
	NSString *title=[item valueForProperty:MPMediaItemPropertyTitle];
	NSString *creator=[item valueForProperty:MPMediaItemPropertyArtist];
	NSString *album=[item valueForProperty:MPMediaItemPropertyAlbumTitle];
	NSNumber *duration=[item valueForProperty:MPMediaItemPropertyPlaybackDuration];
	NSString *source=@"P"; //Choosen by user.
	NSMutableDictionary *track = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:(creator==nil)?@"":creator,(title==nil)?@"":title,[NSString stringWithFormat:@"%i",1000*[duration intValue]],(album==nil)?@"":album,(source==nil)?@"":source, nil]
																	forKeys:[NSArray arrayWithObjects:@"creator", @"title",  @"duration", @"album", @"source", nil]];	
	return track;	
}
@end
