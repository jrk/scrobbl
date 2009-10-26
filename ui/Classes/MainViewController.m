//
//  MainViewController.m
//  scrobble
//
//  Created by Tony Hoyle on 16/08/2008.
//  Licensed under the GNU GPL v2
//

#import "MainViewController.h"
#import "MainView.h"

@implementation MainViewController

@synthesize scrobbleTunes;
@synthesize scrobbleEdge;
@synthesize scrobblePodcasts;
@synthesize songsScrobbled;
@synthesize songsInQueue;
@synthesize scrobblerState;
@synthesize lastResult;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Custom initialization
	}
	return self;
}

 - (void)viewDidLoad {
	 if([[NSUserDefaults standardUserDefaults] objectForKey:@"scrobbleOverEDGE"] == nil)
		 [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"scrobbleOverEDGE"];
	 if([[NSUserDefaults standardUserDefaults] objectForKey:@"scrobblePodcasts"] == nil)
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"scrobblePodcasts"];
	 if([[NSUserDefaults standardUserDefaults] objectForKey:@"scrobblerEnabled"] == nil)
		 [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"scrobblerEnabled"];
			 
	 [scrobbleEdge setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"scrobbleOverEDGE"] integerValue]?TRUE:FALSE];
	 [scrobblePodcasts setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"scrobblePodcasts"] integerValue]?TRUE:FALSE];

	 [self updateState:nil];
	 timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateState:) userInfo:NULL repeats:YES];
 }
 
- (void)updateState:(NSTimer*)timer {
	int iscrobblerState;
	NSString *ilastResult;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	[scrobbleTunes setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"scrobblerEnabled"] integerValue]?TRUE:FALSE];
	
	[songsScrobbled setText:[[[NSUserDefaults standardUserDefaults] objectForKey:@"totalScrobbled"] stringValue]];
	[songsInQueue setText:[[[NSUserDefaults standardUserDefaults] objectForKey:@"queueCount"] stringValue]];
	
	iscrobblerState = [[[NSUserDefaults standardUserDefaults] objectForKey:@"scrobblerState"] integerValue];
	ilastResult = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastResult"];

	switch(iscrobblerState) {
		case SCROBBLER_OFFLINE:
			[scrobblerState setText:@"Idle"];
			break;
		case SCROBBLER_AUTHENTICATING:
			[scrobblerState setText:@"Authenticating"];
			break;
		case SCROBBLER_READY:
			[scrobblerState setText:@"Online"];
			break;
		case SCROBBLER_SCROBBLING:
			[scrobblerState setText:@"Scrobbling"];
			break;
		case SCROBBLER_NOWPLAYING:
			[scrobblerState setText:@"Updating Now Playing"];
			break;
	}
	
	if(ilastResult)
		[lastResult setText:ilastResult];
	else
		[lastResult setText:@"-"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[timer invalidate];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[super dealloc];
}
extern int uid;
- (IBAction)scrobbleTunesChanged:(id)sender
{
	BOOL on = [scrobbleTunes isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:on?1:0 forKey:@"scrobblerEnabled"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	/*
	NSLog(@"Real UID\t= %d\n", getuid());
    NSLog(@"Effective UID\t= %d\n", geteuid());
    NSLog(@"Real GID\t= %d\n", getgid());
    NSLog(@"Effective GID\t= %d\n", getegid());
	setuid(0);
	NSLog(@"Real UID\t= %d\n", getuid());
    NSLog(@"Effective UID\t= %d\n", geteuid());
    NSLog(@"Real GID\t= %d\n", getgid());
    NSLog(@"Effective GID\t= %d\n", getegid());*/
	if(on)
	{
		system("/Applications/scrobble.app/launchctl load /System/Library/LaunchDaemons/org.nodomain.scrobbled.plist"); //; /Applications/scrobble.app/launchctl start org.nodomain.scrobbled");
	//	system("/Applications/scrobble.app/launchctl load /Applications/scrobble.app/scrobbled/org.nodomain.scrobbled.plist; /Applications/scrobble.app/launchctl  start org.nodomain.scrobbled");
	/*	NSLog(@"/bin/launchctl load /System/Library/LaunchDaemons/org.nodomain.scrobbled.plist");
		system("/bin/launchctl load /System/Library/LaunchDaemons/org.nodomain.scrobbled.plist"); 
		NSLog(@"Done");
		NSLog(@"/bin/launchctl start org.nodomain.scrobbled");
		system("/bin/launchctl start org.nodomain.scrobbled");
		NSLog(@"Done");*/
	}
	else
	{
		system("/Applications/scrobble.app/launchctl unload /System/Library/LaunchDaemons/org.nodomain.scrobbled.plist");
		//NSLog(@"/bin/launchctl stop org.nodomain.scrobbled");
		//system("/bin/launchctl stop org.nodomain.scrobbled");
		//NSLog(@"Done");

	}
	//seteuid(uid);

}

- (IBAction)scrobbleEdgeChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[scrobbleEdge isOn]?1:0 forKey:@"scrobbleOverEDGE"];
}

- (IBAction)scrobblePodcastsChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[scrobblePodcasts isOn]?1:0 forKey:@"scrobblePodcasts"];
}

@end
