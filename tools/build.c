/*
 *	linux/tools/build.c
 *	Song Li
 */

/*
 * This file builds a disk-image from three different files:
 *
 * - bootsect
 * - setup
 * - system
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

#define DEFAULT_MAJOR_ROOT 3
#define DEFAULT_MINOR_ROOT 6

void die(char * str)
{
    fprintf(stderr,"%s\n",str);
    exit(1);
}

void usage(void)
{
	die("Usage: build bootsect setup system [rootdev] [> image]");
}


int main(int argc, char ** argv)
{
	struct stat sb;
	//printf("%d", argc);
	if ((argc != 4) && (argc != 5))
		usage();

	if (argc == 5)
	{
		if (strcmp(argv[4], "FLOPPY"))
		{
			// Floppy is not the root device, get the attribute of device
			if (stat(argv[4], &sb))
			{
				perror(argv[4]);
				die("Could not stat root device");
			}
		// why?
		major_root = MAJOR(sb.st_rdev);
		minor_root = MINOR(sb.st_rdev);
		}
		else
		{
            major_root = 0;
            minor_root = 0;

		}
	} else
	{
		major_root = DEFAULT_MAJOR_ROOT;
		minor_root = DEFAULT_MINOR_ROOT;
	}
	fprintf(stderr, "Root device is (%d, %d)\n", major_root, minor_root);
	return 0;
}


