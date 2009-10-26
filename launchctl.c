/*
 *  launchctl.c
 *  scrobbled
 *
 */
#include <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
static char *opts[] = {
	"start",
	"stop",
	"load",
	"unload"
};
static char *cmds[] = {
	"/bin/launchctl start org.nodomain.scrobbled",
	"/bin/launchctl stop org.nodomain.scrobbled",
	"/bin/launchctl load -w /System/Library/LaunchDaemons/org.nodomain.scrobbled.plist",
	"/bin/launchctl stop org.nodomain.scrobbled; /bin/launchctl unload -w /System/Library/LaunchDaemons/org.nodomain.scrobbled.plist"
};

int main(int argc, char *argv[]) {
	/*FILE *pFile;
	pFile = fopen ("/var/mobile/launchctl.log" , "a");
	fprintf(pFile, "Got called as: ");	
	for(int i=0;i<argc;i++)
		fprintf(pFile, "%s ",argv[i]);
	fprintf(pFile,"\n");
	*/

	if ( argc >= 2 ) {
		for(int i=0;i<4;i++) {
			if(!strcmp(opts[i],argv[1])) {
				if(i==2 || i==3) {
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[[NSUserDefaults standardUserDefaults] setInteger:i==2?1:0 forKey:@"scrobblerEnabled"];
					[[NSUserDefaults standardUserDefaults] synchronize];
					[pool release];

				}
				setuid(0);
				system(cmds[i]);
				return(0);
			}
		}
	}
	printf("usage: %s [start | stop | load | unload]\n", argv[0]); 
	return(EXIT_FAILURE);
}