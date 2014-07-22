#
# if you want the ram-disk device, define this to be the
# size in blocks.
#
RAMDISK = #-DRAMDISK=512

AS86    =as86 -0 -a
LD86    =ld86 -0

AS  = as
LD  = ld
LDFLAGS =-s -x -M
CC  =gcc $(RAMDISK)
CFLAGS  =-Wall -O -fstrength-reduce -fomit-frame-pointer
CPP =cpp -nostdinc -Iinclude

#
# ROOT_DEV specifies the default root-device when making the image.
# This can be either FLOPPY, /dev/xxxx or empty, in which case the
# default of /dev/hd6 is used by 'build'.
#
ROOT_DEV=/dev/hd6



.c.s:
    $(CC) $(CFLAGS) \
    -nostdinc -Iinclude -S -o $*.s $<
.s.o:
    $(AS) -o $*.o $<
.c.o:
    $(CC) $(CFLAGS) \
    -nostdinc -Iinclude -c -o $*.o $<




