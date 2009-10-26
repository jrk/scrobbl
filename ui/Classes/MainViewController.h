//
//  MainViewController.h
//  scrobble
//
//  Created by Tony Hoyle on 16/08/2008.
//  Licensed under the GNU GPL v2
//

#import <UIKit/UIKit.h>
#import "../../Classes/shared.h"

@interface MainViewController : UIViewController {
	IBOutlet UISwitch *scrobbleTunes;
	IBOutlet UISwitch *scrobbleEdge;
	IBOutlet UISwitch *scrobblePodcasts;
	IBOutlet UILabel *songsScrobbled;
	IBOutlet UILabel *songsInQueue;
	IBOutlet UILabel *scrobblerState;
	IBOutlet UILabel *lastResult;
	
	NSTimer *timer;
}
- (IBAction)scrobbleTunesChanged:(id)sender;
- (IBAction)scrobbleEdgeChanged:(id)sender;
- (IBAction)scrobblePodcastsChanged:(id)sender;

- (void)updateState:(NSTimer*)sender;

@property (nonatomic, retain) UISwitch *scrobbleTunes;
@property (nonatomic, retain) UISwitch *scrobbleEdge;
@property (nonatomic, retain) UISwitch *scrobblePodcasts;
@property (nonatomic, retain) UILabel *songsScrobbled;
@property (nonatomic, retain) UILabel *songsInQueue;
@property (nonatomic, retain) UILabel *scrobblerState;
@property (nonatomic, retain) UILabel *lastResult;


@end
