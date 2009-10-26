//
//  FlipsideViewController.m
//  test
//
//  Created by Tony Hoyle on 07/09/2008.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "FlipsideViewController.h"


@implementation FlipsideViewController

@synthesize username;
@synthesize password;
@synthesize enableDebug;
@synthesize enableStatusBar;

- (void)viewDidLoad {
	[username setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"]];
	[password setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_password"]];
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"loggingEnabled"] == nil)
		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"loggingEnabled"];
	[enableDebug setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"loggingEnabled"] integerValue]?TRUE:FALSE];
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"statusBarEnabled"] == nil)
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"statusBarEnabled"];
	[enableStatusBar setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"statusBarEnabled"] integerValue]?TRUE:FALSE];
}
- (void)viewWillDisappear:(BOOL)animated {
	//NSLog(@"View will disappear");
	//int uid = getuid();
	//setuid(0);
	system("/Applications/scrobble.app/launchctl stop org.nodomain.scrobbled; /Applications/scrobble.app/launchctl start org.nodomain.scrobbled");
	//system("/Applications/scrobble.app/launchctl stop org.nodomain.scrobbled; /Applications/scrobble.app/launchctl load /Applications/scrobble.app/scrobbled/org.nodomain.scrobbled.plist; /Applications/scrobble.app/launchctl start org.nodomain.scrobbled");
	//system("launchctl stop org.nodomain.scrobbled; launchctl load /Applications/scrobble.app/scrobbled/org.nodomain.scrobbled.plist; launchctl start org.nodomain.scrobbled");
	//seteuid(uid);
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
	[[NSUserDefaults standardUserDefaults] synchronize];
	[super dealloc];
}

- (IBAction)usernameChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setValue:[username text] forKey:@"lastfm_user"];
}

- (IBAction)usernameExit:(id)sender
{
	[password becomeFirstResponder];
}

- (IBAction)passwordChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setValue:[password text] forKey:@"lastfm_password"];
}

- (IBAction)passwordExit:(id)sender
{
	[password resignFirstResponder];
}

- (IBAction)enableDebugChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[enableDebug isOn]?1:0 forKey:@"loggingEnabled"];
}

- (IBAction)enableStatusBarChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[enableStatusBar isOn]?1:0 forKey:@"statusBarEnabled"];
}


@end
