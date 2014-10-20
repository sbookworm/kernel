/*
 * linux/init/main.c
 *
 */

#define __LIBRARY__

#include <unistd.h>
#include <time.h>

// defined in boot/bootsetup.s ROOT_DEV 508(0x1FC),
// and start from 0x9000, so 0x901FC
#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)
// cannot understand why the drive info stored here
#define DRIVE_INFO (*(struct drive_info *)0x90080)


void main(void) {

	ROOT_DEV = ORIG_ROOT_DEV;
	drive_info = DRIVE_INFO;
}

