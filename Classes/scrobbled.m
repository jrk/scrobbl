/* scrobbled.m - Scrobbler Daemon for Apple iPhone
 * Copyright (C) 2007 Sam Steele
 *
 * This file is part of MobileScrobbler.
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
#import "Scrobbler.h"
#include "NSString+MD5.h"

#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>

int debug;

//From Nate True's dock application:
pid_t springboard_pid() {
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
		sleep( 1 );
	}	
	
	if (err) {
		free(process_buffer);
		return -1;
	}
	
	count = length / sizeof(struct kinfo_proc);
	
	kp = process_buffer;
	
	for (loop = 0; (loop < count) && (spring_pid == -1); loop++) {
		if (!strcasecmp(kp->kp_proc.p_comm,"SpringBoard")) {
			spring_pid = kp->kp_proc.p_pid;
		}
		kp++;
	}
	
	free(process_buffer);
	
	return spring_pid;
}

uid_t springboard_uid() {
	uint32_t	    i;
	size_t			length;
	int32_t			err, count;
	struct kinfo_proc	   *process_buffer;
	struct kinfo_proc      *kp;
	int				mib[ 3 ] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
	uid_t           spring_uid;
	int             loop;
	
	spring_uid = -1;
	
	sysctl( mib, 3, NULL, &length, NULL, 0 );
	
	if (length == 0)
		return -1;
	
	process_buffer = (struct kinfo_proc *)malloc(length);
	
	for ( i = 0; i < 60; ++i ) {
		// in the event of inordinate system load, transient sysctl() failures are
		// possible.  retry for up to one minute if necessary.
		if ( ! ( err = sysctl( mib, 3, process_buffer, &length, NULL, 0 ) ) ) break;
		sleep( 1 );
	}	
	
	if (err) {
		free(process_buffer);
		return -1;
	}
	
	count = length / sizeof(struct kinfo_proc);
	
	kp = process_buffer;
	
	for (loop = 0; (loop < count) && (spring_uid == -1); loop++) {
		if (!strcasecmp(kp->kp_proc.p_comm,"SpringBoard")) {
			spring_uid = kp->kp_eproc.e_pcred.p_ruid;
		}
		kp++;
	}
	
	free(process_buffer);
	
	return spring_uid;
}

void usage()
{
	printf("usage: scrobbled [-u username -p password] [-d] [-e val] [-o val] [-x]\n");
	printf("\t-u\tSet username (requires password)\n");
	printf("\t-p\tSet password\n");
	printf("\t-d\tEnable logging\n");
	printf("\t-e\tScrobble over Edge/3G (1/0)\n");
	printf("\t-o\tScrobble podcasts (1/0)\n");
	printf("\t-x\tSet persistent values and exit\n");
}

StatusBarController *statusBar = nil;

void removeIcon(int status) {
	if(statusBar != nil) {
		[statusBar cleanStatusBar];
	}
	exit(0);
}

int main(int argc, char *argv[]) {
	
	int opt;
	const char *username=NULL, *password=NULL;
	int exit = 0;
	NSUserDefaults *defaults;
	
	debug = 0;
	
	struct sigaction sa;
	sa.sa_handler = removeIcon;
	
	sigaction(SIGTERM,  &sa, NULL);	
	sigaction(SIGHUP,  &sa, NULL);
	sigaction(SIGKILL,  &sa, NULL);
	sigaction(SIGINT,  &sa, NULL);
	
	sleep(2);
	
	//Give SpringBoard time to start up
	while(springboard_pid() == -1) {
		sleep(4);
	}
	
	//printf("SpringBoard running as uid: %i\n", springboard_uid());
	setuid(springboard_uid());
	if(!exit)
		sleep(2);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// This is a variable mainly so I can make the plist file write somewhere else, but
	// as far as I can tell that simply can't be done without changing the application ID,
	// which in turn won't work without an Info.plist
	defaults = [NSUserDefaults standardUserDefaults];
	
	while((opt=getopt(argc, argv, "u:p:h?do:e:x"))!=-1) {
        switch( opt ) {
            case 'u':
				username = optarg;
                break;                
            case 'p':
				password = optarg;
                break;		
			case 'd':
				debug = 1;
				break;
			case 'o':
				[defaults setInteger:atoi(optarg) forKey:@"scrobblePodcasts"];
				break;
			case 'e':
				[defaults setInteger:atoi(optarg) forKey:@"scrobbleOverEDGE"];
				break;
			case 'x':
				exit = 1;
				break;
            case 'h':  
            case '?':
			default:
                usage();
				[pool release];
				return 0;
        }
    }
 	
	if(username && !password)
	{
		usage();
		[pool release];
		return 0;
	}
			
	if(username)
	{
		[defaults setValue:[NSString stringWithUTF8String:username] forKey:@"lastfm_user"];
		[defaults setValue:[NSString stringWithUTF8String:password] forKey:@"lastfm_password"];
	}

	if(exit)
	{
		[defaults synchronize];
		[pool release];
		return 0;
	}
	
	Scrobbler *theScrobbler = [[Scrobbler alloc] init];
	int ret = [theScrobbler run];
	[defaults synchronize];
	[pool release];
	return ret;
}
