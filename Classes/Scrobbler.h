/* Scrobbler.h - AudioScrobbler client class
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "shared.h"
#import "StatusBarController.h"
#import "Player.h"

#define MAXSUBMISSIONCOUNT 50
/*
#define SCROBBLER_OFFLINE 0
#define SCROBBLER_AUTHENTICATING 1
#define SCROBBLER_READY 2
#define SCROBBLER_SCROBBLING 3
#define SCROBBLER_NOWPLAYING 4

NSString *kTrackDidBecomeAvailable = @"LastFMRadio_TrackDidBecomeAvailable";
NSString *kTrackDidFinishLoading = @"LastFMRadio_TrackDidFinishLoading";
NSString *kTrackDidFinishPlaying = @"LastFMRadio_TrackDidFinishPlaying";
NSString *kTrackDidFailToStream = @"LastFMRadio_TrackDidFailToStream";
*/
#define TRACKDIDCHANGE @"LastFM_TrackDidChange"


@interface Scrobbler : NSObject {
	NSString *_sess;
	NSString *_nowPlayingURL;
	NSString *_scrobbleURL;
	NSURLConnection *_connection;
	NSMutableData *_receivedData;
	int _scrobblerState;
	int _scrobblerError;
	NSMutableArray *_queue;
	NSTimer *_queueTimer,*_handshakeTimer,*_statusTimer;
	NSTimeInterval _handshakeTimerInterval;
	int _submissionCount;
	int _maxSubmissionCount;
	NSTimer *_timer;
	BOOL _submitted;
	BOOL _sentNowPlaying;
	int _oldNetworkType;
	BOOL _threadToTerminate;
	int _totalScrobbled;
	Player *_player;
	pid_t springboardpid;
}
- (BOOL)scrobbleTrack:(NSString *)title byArtist:(NSString *)artist onAlbum:(NSString *)album withStartTime:(int)startTime withDuration:(int)duration fromSource:(NSString *)source;
- (void)nowPlayingTrack:(NSString *)title byArtist:(NSString *)artist onAlbum:(NSString *)album withDuration:(int)duration;
- (void)handshake:(NSTimer *)theTimer;
- (void)flushQueue:(NSTimer *)theTimer;
- (void)doQueueTimer:(NSTimeInterval)inSeconds;
- (void)doHandshakeTimer;
- (void)loadQueue;
- (void)saveQueue;
- (void)update:(NSTimer *)theTimer;
- (void)cancelTimer;
-(BOOL)hasNetworkConnection;
-(BOOL)hasWiFiConnection;
- (void)setResult:(NSString *)result;
- (void)setState:(scrobbleState_t)state;
-(int)run;
- (void) status;
-(void)terminateThread;
@end

extern StatusBarController *statusBar;
