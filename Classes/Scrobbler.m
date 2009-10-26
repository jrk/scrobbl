/* Scrobbler.m - AudioScrobbler client class
 * 
 * Copyright 2009 Last.fm Ltd.
 *   - Primarily authored by Sam Steele <sam@last.fm>
 *
 * This file is part of MobileLastFM.
 *
 * MobileLastFM is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MobileLastFM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MobileLastFM.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/NSCharacterSet.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NSString+MD5.h"
#include "version.h"
#import "NSString+URLEscaped.h"
#import "MPMediaItem+Track.h"
#include <SystemConfiguration/SCNetworkReachability.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/errno.h>
#import "Scrobbler.h"
#include <sys/types.h>

#define __LIBRARY_PATH @"/var/mobile/Library/scrobbled"
#define LIBRARY_PATH(file) [NSString stringWithFormat:@"%@/%@", __LIBRARY_PATH, file]
pid_t springboard_pid();

@implementation Scrobbler
#include "NSLogOverride.h"
// Network connection should use SCNetworkReachabilityCreateWithAddressPair together with SCNetworkReachabilitySetCallback to get notifications when the network changes,
// then we can scrobble queue the moment we get a connnection even if we aren't playing. Could also be used to improve battery life - e.g. an option to never wake up the
// radio and only send when wifi/edge/3G is active.
-(BOOL)hasNetworkConnection {
	if([[[NSUserDefaults standardUserDefaults] objectForKey: @"scrobbleOverEDGE"] integerValue]) {
		SCNetworkReachabilityRef reach = SCNetworkReachabilityCreateWithName(kCFAllocatorSystemDefault, "ws.audioscrobbler.com");
		SCNetworkReachabilityFlags flags;
		SCNetworkReachabilityGetFlags(reach, &flags);
		BOOL ret = (kSCNetworkReachabilityFlagsReachable & flags) || (kSCNetworkReachabilityFlagsConnectionRequired & flags);
		CFRelease(reach);
		reach = nil;
		return ret;
	} else {
		//if scrobble over edge is disabled then we pretend that we're only connected if we have wifi
		return [self hasWiFiConnection];
	}
}
-(BOOL)hasWiFiConnection {
	SCNetworkReachabilityRef reach = SCNetworkReachabilityCreateWithName(kCFAllocatorSystemDefault, "ws.audioscrobbler.com");
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(reach, &flags);
	BOOL ret = (kSCNetworkFlagsReachable & flags) && !(kSCNetworkReachabilityFlagsIsWWAN & flags);
	CFRelease(reach);
	reach = nil;
	return ret;
}


- (void)setResult:(NSString *)result {
	[[NSUserDefaults standardUserDefaults] setValue:result forKey:@"lastResult"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setState:(scrobbleState_t)state {
	_scrobblerState = state;
	[[NSUserDefaults standardUserDefaults] setInteger:state forKey:@"scrobblerState"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(int)run {
	NSLog(@"Starting scrobbled\n");
	_threadToTerminate = NO;
	// create the runloop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		// run the loop!
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES && _threadToTerminate==NO);
	return 1;
}

-(void)terminateThread {
	_threadToTerminate = YES;
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

- (void) status {
//	NSLog(@"Scrobbler state: %i, network status: %i, queue{timer: %@, length:%i}, handshake{timer: %@, interval: %f}, connection: %@, sess: %@\n",
//		  _scrobblerState,_oldNetworkType,_queueTimer==nil ? @"NO" : @"YES",[_queue count],_handshakeTimer==nil ? @"NO" : @"YES",_handshakeTimerInterval,_connection==nil ? @"NO" : @"YES",_sess);
}

- (id) init {
	
	[[NSFileManager defaultManager] createDirectoryAtPath:__LIBRARY_PATH attributes:nil];
	_sess = nil;
	_nowPlayingURL = nil;
	_scrobbleURL = nil;
	_queue = [[NSMutableArray alloc] initWithCapacity:20];
	_queueTimer = nil;
	[self setState:SCROBBLER_OFFLINE];
	[self setResult:@""];
	_totalScrobbled = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalScrobbled"];
	_handshakeTimerInterval = 5;
	_maxSubmissionCount = MAXSUBMISSIONCOUNT;
	_connection = nil;
	_submitted = NO;
	_sentNowPlaying = NO;
	_oldNetworkType = 0;
	[self loadQueue];
	_timer = [NSTimer scheduledTimerWithTimeInterval:1
																						target:self
																					selector:@selector(update:)
																					userInfo:NULL
																					 repeats:NO];
	statusBar=[[StatusBarController alloc] init];
	[statusBar cleanStatusBar];
	[statusBar defaultStatusBarImage];
	springboardpid=-1;
	_player =  [[Player alloc] init];
	return [super init];
}

- (void)cancelTimer {
	[_timer invalidate];
}

- (void)dealloc {
	[_player release];
	[statusBar release];
	[_sess release];
	[_nowPlayingURL release];
	[_scrobbleURL release];
	[_connection release];
	[_receivedData release];
	[_queue release];
	[_statusTimer release];
	[_queueTimer release];
	[super dealloc];
}

- (void)loadQueue {
	NSString *filename = [__LIBRARY_PATH  stringByAppendingPathComponent:@"queue.plist"];
	NSArray *savedQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
	if(savedQueue != nil) {
		[_queue addObjectsFromArray:savedQueue];
		NSLog(@"Loaded queue with %i items from %@\n", [_queue count], filename);
	}
	[[NSUserDefaults standardUserDefaults] setInteger:[_queue count] forKey: @"queueCount"];

}
- (void)saveQueue {
	NSString *filename = [__LIBRARY_PATH  stringByAppendingPathComponent:@"queue.plist"];
	if(![NSKeyedArchiver archiveRootObject:_queue toFile:filename]) 
		NSLog(@"Unable to save queue");
}
- (void)update:(NSTimer *)timer {
	//Check if springboard restarted
	pid_t pid=springboard_pid();
	if(pid != springboardpid && pid !=-1) {
		[statusBar refresh];
		springboardpid=pid;
	}
	
	int networkType;
		
	if([self hasWiFiConnection]) {
		networkType = 2;
	} else if([self hasNetworkConnection]) {
		networkType = 1;
	} else {
		networkType = 0;
	}
	
	if(networkType != _oldNetworkType && [self hasNetworkConnection]) {
		NSLog(@"Network connection changed, handshaking\n");
		_handshakeTimerInterval = 5;
		[self doHandshakeTimer];
	}
	if(_oldNetworkType>0 && networkType == 0) {
		NSLog(@"Lost network connection/not scrobbling over edge\n");
	}
	_oldNetworkType = networkType;
	BOOL playing = [_player isPlaying];
	
	if([_queue count] && !playing)
		[self doQueueTimer:0]; //Run the queue timer, otherwise idle queues don't get sent w/o network transitions
	
	if(playing && [[[NSUserDefaults standardUserDefaults] objectForKey: @"scrobblerEnabled"] integerValue]) {
		NSDictionary *track = [_player trackInfo];
		if(track != nil) {
			if([_player trackPosition] > 240 || (([_player trackPosition] * 1000.0f) / [[track objectForKey:@"duration"] floatValue]) > 0.5) {
				if(!_submitted) {
					[self scrobbleTrack:[track objectForKey:@"title"]
										 byArtist:[track objectForKey:@"creator"]
											onAlbum:[track objectForKey:@"album"]
								withStartTime:[[track objectForKey:@"startTime"] intValue]
								 withDuration:[[track objectForKey:@"duration"] intValue]
									 fromSource:[track objectForKey:@"source"]];
					_submitted = TRUE;
				}
			} else {
				_submitted = FALSE;
			}
			if([_player trackPosition] > 10) {
				if(!_sentNowPlaying && [self hasNetworkConnection]) {
					[self nowPlayingTrack:[track objectForKey:@"title"] byArtist:[track objectForKey:@"creator"] onAlbum:[track objectForKey:@"album"] withDuration:[[track objectForKey:@"duration"] intValue]];
					_sentNowPlaying = TRUE;
				}
			} else {
				_sentNowPlaying = FALSE;
				NSLog(@"Found new Track\n");
				[self doQueueTimer:0];
			}
		}
	}
	if(playing) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:10
																							target:self
																						selector:@selector(update:)
																						userInfo:NULL
																						 repeats:NO];
	} else {
		_timer = [NSTimer scheduledTimerWithTimeInterval:30
																							target:self
																						selector:@selector(update:)
																						userInfo:NULL
																						 repeats:NO];
	}
}
- (void)handshake:(NSTimer *)timer  {
	if(_handshakeTimer != nil) {
		if([_handshakeTimer isValid])
			[_handshakeTimer invalidate];
		_handshakeTimer = nil;
	}
	NSString *timestamp = [NSString stringWithFormat:@"%qu", (u_int64_t)[[NSDate date] timeIntervalSince1970]];
	NSString *auth = [[NSString stringWithFormat:@"%@%@", [[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_password"] md5sum], timestamp] md5sum];
	NSString *authURL = [NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=%@&v=%@&u=%@&t=%@&a=%@",
											 SCROBBLER_ID,
											 SCROBBLER_VERSION,
											 [[[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] lowercaseString] URLEscaped],
											 timestamp,
											 auth];
	NSURL *theURL = [NSURL URLWithString:authURL];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];

	if(_connection) {
		return;
	}
	
	if([self hasNetworkConnection]) {
		NSLog(@"Authenticating...\n");
		[self setState: SCROBBLER_AUTHENTICATING];
		_connection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	}
	if (_connection) {
		_receivedData=[[NSMutableData alloc] init];
	} else {
		[self setState: SCROBBLER_OFFLINE];
	}	
}

- (BOOL)scrobbleTrack:(NSString *)title byArtist:(NSString *)artist onAlbum:(NSString *)album withStartTime:(int)startTime withDuration:(int)duration fromSource:(NSString *)source {
	if([[[[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrobble"] objectForKey:@"startTime"] intValue] != startTime ||
	   ![[[[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrobble"] objectForKey:@"title"] isEqualToString:title] ||
		 ![[[[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrobble"] objectForKey:@"artist"] isEqualToString:artist]) {
		NSMutableDictionary *track = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:(artist==nil)?@"":artist,(title==nil)?@"":title,[NSString stringWithFormat:@"%i",startTime],[NSString stringWithFormat:@"%i",duration/1000],(album==nil)?@"":album,(source==nil)?@"":source, nil]
																																		forKeys:[NSArray arrayWithObjects:@"artist", @"title", @"startTime", @"duration", @"album", @"source", nil]];
		NSLog(@"Queueing %@ - %@ - %@ for submission\n", artist, album, title);
		[[NSUserDefaults standardUserDefaults] setObject:track forKey:@"lastScrobble"];
		[[NSUserDefaults standardUserDefaults] setInteger:[_queue count] forKey: @"queueCount"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[_queue addObject:track];
		[self saveQueue];
		return TRUE;
	} else {
		NSLog(@"Ignoring duplicate %@ - %@ - %@\n", artist, album, title);
	}
	return FALSE;
}

- (void)doHandshakeTimer {
	if(_handshakeTimer == nil) {
		NSLog(@"Handshake scheduled in %.1f seconds\n", _handshakeTimerInterval);
		_handshakeTimer = [NSTimer scheduledTimerWithTimeInterval:_handshakeTimerInterval
																								target:self
																				selector:@selector(handshake:)
																							userInfo:NULL
																							 repeats:NO];
		_handshakeTimerInterval *= 2;
		if(_handshakeTimerInterval < 60) {
			_handshakeTimerInterval = 60;
		} else if(_handshakeTimerInterval > 240) {
			_sess = nil;
		}
		if(_handshakeTimerInterval > 7200) _handshakeTimerInterval = 7200;
	}
}

- (void)doQueueTimer:(NSTimeInterval)inSeconds {
	if(_queueTimer == nil) {
		NSLog(@"Queue flush scheduled in %.1f seconds\n", inSeconds);
		_queueTimer = [NSTimer scheduledTimerWithTimeInterval:inSeconds
														   target:self
														 selector:@selector(flushQueue:)
														 userInfo:NULL
														  repeats:NO];
	}
}

- (void)nowPlayingTrack:(NSString *)title byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(int)duration {
	if(_sess == nil || _connection) {
		_sentNowPlaying = FALSE;
		return;
	}	
		
	NSMutableData *postData=[[NSMutableData alloc] init];
	[postData appendData:[[NSString stringWithFormat:@"s=%@",_sess] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithFormat:@"&a=%@&t=%@&b=%@&l=%i&n=&m=",
												 [artist URLEscaped],
												 [title URLEscaped],
												 [album URLEscaped],
												 (duration/1000)
												 ] dataUsingEncoding:NSUTF8StringEncoding]];

	NSLog(@"Sending currently playing track to %@\n", _nowPlayingURL);

	NSURL *theURL = [NSURL URLWithString:_nowPlayingURL];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:postData];
	[postData release];
	
	if([self hasNetworkConnection]) {
		[self setState:SCROBBLER_NOWPLAYING];
		_connection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	}	
	if (_connection) {
    _receivedData=[[NSMutableData alloc] init];
	}	
}

- (void)flushQueue:(NSTimer *)theTimer {
	NSEnumerator *enumerator = [_queue objectEnumerator];
	NSString *trackStr;
	int i=0;
	id track;
	if(_queueTimer != nil) {
		if([_queueTimer isValid])
			[_queueTimer invalidate];
		_queueTimer = nil;
	}
	
	if([_queue count] < 1)
		return;
	NSLog(@"Flushing queue.\n");

	if(_connection) {
		[self doQueueTimer:30];
		return;
	}	
	
	if(_sess == nil) {
		[self doHandshakeTimer];
		return;
	}	
	
	if(![self hasNetworkConnection]) {
		[self setState: SCROBBLER_OFFLINE];
		_handshakeTimerInterval = 60;
		return;
	}
	NSMutableData *postData=[[NSMutableData alloc] init];
	[postData appendData:[[NSString stringWithFormat:@"s=%@",_sess] dataUsingEncoding:NSUTF8StringEncoding]];
	_submissionCount = 0;
	
	while((track = [enumerator nextObject]) && i < _maxSubmissionCount) {
		trackStr = [NSString stringWithFormat:@"&a[%i]=%@&t[%i]=%@&i[%i]=%@&o[%i]=%@&r[%i]=%@&l[%i]=%@&b[%i]=%@&n[%i]=&m[%i]=",
								i, [[track objectForKey:@"artist"] URLEscaped],
								i, [[track objectForKey:@"title"] URLEscaped],
								i, [track objectForKey:@"startTime"],
								i, [track objectForKey:@"source"] ? [track objectForKey:@"source"] : @"P",
								i, [track objectForKey:@"rating"] ? [track objectForKey:@"rating"] : @"",
								i, [track objectForKey:@"duration"],
								i, [[track objectForKey:@"album"] URLEscaped],
								i, i
								];
		[postData appendData:[trackStr dataUsingEncoding:NSUTF8StringEncoding]];
		i++;
	}
	
	if([postData length] == [[NSString stringWithFormat:@"s=%@",_sess] length]) {
		[postData release]; //posible memory leak in Last.fm code. Don't see how we get here though!
		[_queue removeAllObjects];
	} else {
		_submissionCount = i;
		NSLog(@"Sending %i / %i tracks...\n", i, [_queue count]);

		NSURL *theURL = [NSURL URLWithString:_scrobbleURL];
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
		
		[theRequest setHTTPMethod:@"POST"];
		[theRequest setHTTPBody:postData];
		[postData release];
		
		_connection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
		if (_connection) {
			[self setState:SCROBBLER_SCROBBLING];
			_receivedData=[[NSMutableData alloc] init];
		} else {
			[self doQueueTimer:10];
		}
	}
}

#pragma mark Connection Methods
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString *theResponseString = [[NSString alloc] initWithData:_receivedData encoding:NSASCIIStringEncoding];
	NSArray *list = [theResponseString componentsSeparatedByString:@"\n"];
	[theResponseString release];
	int i,queuetime=1;
	[_connection release];
	_connection = nil;
	[_receivedData release];
	_receivedData = nil;
	
	NSString *scrobblerResult = [[list objectAtIndex: 0] retain];
	NSLog(@"Server response: %@\n", scrobblerResult);
	[self setResult:scrobblerResult];

	switch(_scrobblerState) {
		case SCROBBLER_AUTHENTICATING:
			if([scrobblerResult isEqualToString:@"OK"]) {
				[_sess release];
				_sess = [[list objectAtIndex: 1] retain];
				[_nowPlayingURL release];
				_nowPlayingURL = [[list objectAtIndex: 2] retain];
				[_scrobbleURL release];
				_scrobbleURL = [[list objectAtIndex: 3] retain];
				[self setState:SCROBBLER_READY];
				NSLog(@"Authenticated. Session: %@\n", _sess);
				NSLog(@"Scrobble URL:%@\n",_scrobbleURL);
				[[NSUserDefaults standardUserDefaults] setObject:_sess forKey: @"session"];
				[[NSUserDefaults standardUserDefaults] setObject:_nowPlayingURL forKey: @"nowPlayingURL"];
				[[NSUserDefaults standardUserDefaults] setObject:_scrobbleURL forKey: @"scrobbleURL"];
				[[NSUserDefaults standardUserDefaults] synchronize];				
				_handshakeTimerInterval = 5;
			} else {
				[_sess release];
				_sess = nil;
				[_nowPlayingURL release];
				_nowPlayingURL = nil;
				[_scrobbleURL release];
				_scrobbleURL = nil;
				[statusBar addStatusBarImageNamed:IMAGEFAILED forTime:15];
				[self setState:SCROBBLER_OFFLINE];
				[self doHandshakeTimer]; //Start another handshake at double the interval
			}
			break;
		case SCROBBLER_SCROBBLING:
			if([scrobblerResult isEqualToString:@"OK"]) {
				NSLog(@"Scrobble succeeded!\n");
				[statusBar addStatusBarImageNamed:IMAGESUCCESS forTime:7.5];
				for(i=0; [_queue count] > 0 && i < _submissionCount; i++) {
					_totalScrobbled++;
					[_queue removeObjectAtIndex:0];
				}
				[[NSUserDefaults standardUserDefaults] setInteger:_totalScrobbled forKey: @"totalScrobbled"];
				[[NSUserDefaults standardUserDefaults] setInteger:[_queue count] forKey: @"queueCount"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				_maxSubmissionCount = MAXSUBMISSIONCOUNT;
			} else {
				NSLog(@"Error: \"%@\"\n", scrobblerResult);
				[statusBar addStatusBarImageNamed:IMAGEFAILED forTime:15];
				if([scrobblerResult isEqualToString:@"BADSESSION"]) {
					_handshakeTimerInterval = 5;
					[self doHandshakeTimer];
				} else {
					_maxSubmissionCount /= 4;
					if(_maxSubmissionCount < 1) 
					{
						_maxSubmissionCount = 1;
						queuetime=60; //Try again in 1 minutes to avoid hammering server/killing battery by constantly connection
					}
				}
			}
			[self saveQueue];
			break;
	}
	if(_scrobblerState != SCROBBLER_OFFLINE) {
		if(_scrobblerState != SCROBBLER_NOWPLAYING && [_queue count] > 0) {
			[self setState:SCROBBLER_READY];
			[self doQueueTimer:queuetime];
		} else {
			[self setState:SCROBBLER_READY];
		}
	}
	[self status];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_receivedData setLength:0];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_receivedData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	// release the connection, and the data object
	[_connection release];
	_connection = nil;
	
	// receivedData is declared as a method instance elsewhere
	[_receivedData release];
	_receivedData = nil;
	
	// inform the user
	NSLog(@"Connection failed! Error - %@ %@",
				[error localizedDescription],
				[[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	[self setResult:[error localizedDescription]];
	[statusBar addStatusBarImageNamed:IMAGEFAILED forTime:7.5];
	if(_scrobblerState == SCROBBLER_SCROBBLING) {
		[self setState:SCROBBLER_READY];
		[self doQueueTimer:60]; //wait a minute if we got a connection failure
	} else {
		[self setState:SCROBBLER_OFFLINE];
		[self doHandshakeTimer]; //Should increment hard failure counter as per api documentation
	}
	[self status];
}

@end
