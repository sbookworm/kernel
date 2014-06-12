!
! system size is numbers of clicks (16 bytes)
! so the real system size is 0x30000 bytes
!

!SYSSIZE = 0x3000

SETUPLEN = 4 
BOOTSEG = 0x07c0	! the address will be execute by BIOS when powered on
INITSEG = 0x9000	! move code of BOOTSEG to here, real address 0x90000

start:
	mov ax, #BOOTSEG
	mov ds, ax	! move the BOOTSEG to ds(source position)
	mov ax, #INITSEG
	mov es, ax	! move the INITSEG to es(dist position)
	mov cx, #256	! count 256 for rep. move 512 bytes
	sub si, si	! set si=0, si is the point of ds
	sub di, di	! set di=0, di is the point of es
	rep
	movw	! move word for cx(256) times from ds to es. each move si+=2, id+=2
	jmpi go, INITSEG	! jump to INITSEG + go segment

go:	mov ax, cs	! move code seg to ax
	mov ds, ax	! move code seg to data seg
	mov es, ax	! move code seg to extra seg
! init stack, set top at 0x9ff00, 0x9000 * 16 + sp
	mov ss, ax	! set ss to be cs(0x9000)
	mov sp, #0xff00	! set the value to be 0xff00

load_setup:
	mov dx, #0x0000	! drive 0, head 0
	mov cx, #0x0002	! sector 2, track 0
	mov bx, #0x0200 ! dest mem address(begin): 0x90200
! ah(0x02) read sector to memory, al: sector numbers
	mov ax, #0x0200 + SETUPLEN
	int 0x13
	jnc ok_load_setup
	mov dx, #0x0000
	mov ax, #0x0000	! reset the diskette
	int 0x13
	j load_setup

ok_load_setup:
! get disk drive parameters, specifically nr of sectors/track

	mov dl, #0x00	! drive 0
	mov ax, #0x0800	! AH=8 is get the drive parameters
	int 0x13
	mov ch, #0x00	! track 0
	seg cs
	mov sectors, cx
	mov ax, #INITSEG
	mov es, ax
! print some iname messages
	mov ah, #0x03	! read cursor pos
	xor bh, bh
	int 0x10

	mov cx, #24
	mov bx, #0x0007	! page 0, attribute 7
	mov bp, #msg1
	mov ax, #0x1301	! write string, move cursor
	int 0x10

! we have written the message, now
! load the system (at 0x10000)









sectors:
	.word 0

msg1:
    .byte 13,10
    .ascii "Loading system ..."
    .byte 13,10,13,10

