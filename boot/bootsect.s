!
! system size is numbers of clicks (16 bytes)
! so the real system size is 0x30000 bytes
!

SYSSIZE = 0x3000

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text


SETUPLEN = 4 
BOOTSEG = 0x07c0	! the address will be execute by BIOS when powered on
INITSEG = 0x9000	! move code of BOOTSEG to here, real address 0x90000
SYSSEG   = 0x1000           ! system loaded at 0x10000 (65536).
SETUPSEG = 0x9020           ! setup starts here
ENDSEG   = SYSSEG + SYSSIZE     ! where to stop loading


! ROOT_DEV 0x000 - same type of floppy as boot
! 0x301 - first partition on first drive etc
ROOT_DEV = 0x306

entry start
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

	mov ax, #SYSSEG
	mov es, ax
	call read_it
	call kill_motor

! After load the system, check the root-device to use. If the device is
! defined(!=0), nothing is done and the given device is used.
! Otherwise, either /dev/SP0(2.28) or /dev/at0(2.8) depending on the nr
! of the sectors that BIOS reports currently.

	seg cs
	mov ax, root_dev
	cmp ax, #0
	jne root_defined
	seg cs
	mov bx, sectors
	mov ax, #0x0208	! /dev/ps0 - 1.2Mb
	cmp bx, #15
	je root_defined
	mov ax, #0x021c
	cmp bx, #18
	je root_defined
undef_root:
	jmp undef_root	! dead loop
root_defined:
	seg cs
	mov root_dev, ax

! after setup and system loaded, jump to setup-runtine
	jmpi 0, SETUPSEG

sread:  .word 1+SETUPLEN    ! sectors read of current track
head:   .word 0         ! current head
track:  .word 0         ! current track


read_it:
	mov ax, es
	test ax, #0x0fff
die:	jne die	! es must be at 64KB boundary
	xor bx, bx
rp_read:
	mov ax, es
	cmp ax, #ENDSEG
	jb ok1_read
	ret
ok1_read:
	seg cs
	mov ax, sectors
	sub ax, sread
	mov cx, ax
	shl cx, #9
	add cx, bx
	jnc ok2_read
	je ok2_read
	xor ax, ax
	sub ax, bx
	shr	ax, #9
ok2_read:
	call read_track
	mov cx, ax
	add ax, sread
	seg cs
	cmp ax, sectors
	jne ok3_read
	mov ax, #1
	sub ax, head
	jne ok4_read
	jnc track
ok4_read:
	mov head, ax
	xor ax, ax
ok3_read:
	mov sread, ax
	shl cx, #9
	add bx, cx
	jnc rp_read
	mov ax, es
	add ax, #0x1000
	mov es, ax
	xor bx, bx
	jmp rp_read

read_track:
    push ax
    push bx
    push cx
    push dx
    mov dx,track
    mov cx,sread
    inc cx
    mov ch,dl
    mov dx,head
    mov dh,dl
    mov dl,#0
    and dx,#0x0100
    mov ah,#2
    int 0x13
    jc bad_rt
    pop dx
    pop cx
    pop bx
    pop ax
    ret
bad_rt: mov ax,#0
    mov dx,#0
    int 0x13
    pop dx
    pop cx
    pop bx
    pop ax
    jmp read_track

!
! This procedure turns off the floppy drive motor, so
! that we enter the kernel in a known state, and
! don't have to worry about it later.

kill_motor:
    push dx
    mov dx,#0x3f2
    mov al,#0
    outb
    pop dx
    ret

root_dev:
	.word ROOT_DEV

sectors:
	.word 0

msg1:
    .byte 13,10
    .ascii "Loading system ..."
    .byte 13,10,13,10

