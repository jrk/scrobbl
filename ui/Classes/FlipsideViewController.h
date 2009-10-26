//
//  FlipsideViewController.h
//  test
//
//  Created by Tony Hoyle on 07/09/2008.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlipsideViewController : UIViewController {
	IBOutlet UITextField *username;
	IBOutlet UITextField *password;
	IBOutlet UISwitch *enableDebug;
	IBOutlet UISwitch *enableStatusBar;
}

- (IBAction)usernameChanged:(id)sender;
- (IBAction)usernameExit:(id)sender;
- (IBAction)passwordChanged:(id)sender;
- (IBAction)passwordExit:(id)sender;
- (IBAction)enableDebugChanged:(id)sender;
- (IBAction)enableStatusBarChanged:(id)sender;
- (void)viewWillDisappear:(BOOL)animated;

@property (nonatomic, retain) UITextField *username;
@property (nonatomic, retain) UITextField *password;
@property (nonatomic, retain) UISwitch *enableDebug;
@property (nonatomic, retain) UISwitch *enableStatusBar;

@end
