INITSEG  = 0x9000   ! we move boot here - out of the way
SYSSEG   = 0x1000   ! system loaded at 0x10000 (65536).
SETUPSEG = 0x9020   ! this is the current segment

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

entry start
start:

! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov ax, #INITSEG ! this is done in bootsect already, but make sure again
	mov ds, ax
	mov ah, #0x03 ! read cursor pos
	xor bh, bh
	int 0x10
	mov [0], dx ! save it in 0x90000, then con_init fetchs

! get memory size (extended mem, KB)

	mov ah, #0x88
	int 0x15
	mov [2], ax ! save memory size in 0x90002

! get video-card data, save them to 0x90004, 0x90006:

	mov ah, #0x0f
	int 0x10
	mov [4], bx ! bh = display page
	mov [6], ax	! al = video mode, ah = window width

! check for EGA/VGA and some config parameters

	mov ah, #0x12
	mov bl, #0x10
	int 0x10
	mov [8], ax
	mov [10], bx
	mov [12], cx

! get hd0 data

	mov ax, #0x0000
	mov ds, ax
	lds si, [4*0x41] ! save disk data to the table [4*0x41], lenth 0x10 bytes
	mov ax, #INITSEG
	mov es, ax
	mov di, #0x0080	! copy the first disk data to 0x90080
	mov cx, #0x10 ! copy data from [4*0x41] to [0x90080] for 0x10 bytes
	rep
	movsb

! get hd1 data

    mov ax, #0x0000
    mov ds, ax
    lds si, [4*0x43] ! save disk data to the table [4*0x43], lenth 0x10 bytes
    mov ax, #INITSEG
    mov es, ax
    mov di, #0x0080 ! copy the first disk data to 0x90080
    mov cx, #0x10 ! copy data from [4*0x43] to [0x90090] for 0x10 bytes
    rep
    movsb

! check that there is a hd1

	mov ax, #0x01500
	mov dl, #0x81
	int 0x13
	jc no_disk1
	cmp ah, #3
	je is_disk1
no_disk1:
	mov ax, #INITSEG	
	mov es, ax
	mov di, #0x0090
	mov cx, #0x10
	mov ax, #0x00
	rep
	stosb ! clear the [0x90090] to [0x90009f]
is_disk1:

! do nothing, and move to protected mode ...
	cli ! no interrupts allowed

! first move the system to it's right place

	mov ax, #0x0000
	cld
do_move:
	mov es, ax ! es=0x0000, so es:di=0x00000:0x0000 to begin, then += 0x1000
	add ax, #0x1000
	cmp ax, #0x9000
	jz end_move
	mov ds, ax ! source segment, cs:si=0x10000:0x0000
	sub di, di
	sub si, si
	mov cx, #0x8000 ! move #0x8000 words, 64KB
	rep
	movsw
	jmp do_move

! then load the segment descriptions

end_move:
	mov ax, #SETUPSEG
	mov ds, ax
	lidt idt_48
	lgdt gdt_48

! that was painless, now enable A20

	call empty_8042
	mov al, #0xD1 ! command write
	out #0x64, al
	call empty_8042
	mov al, #0xDF
	out #0x60, al
	call empty_8042

! well, that went ok, I hope. Now reprogram the interrupts :-(
! put them right after the intel-reserved hardware interrupts, at
! int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
! messed this up with the original PC, and they haven't been able to
! rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
! which is used for the internal hardware interrupts as well. We just
! have to reprogram the 8259

	mov al, #0x11 ! initialization sequence
	out #0x20, al ! send it to 8259A-1
	.word 0x00eb, 0x00eb ! jmp $+2, jmp $+2
	out #0xA0, al ! and to 8259A-2
	.word 0x00eb, 0x00eb
	mov al, #0x20 ! start of hardware int's(0x20)
	out #0x21, al
    .word   0x00eb,0x00eb
    mov al,#0x04        ! 8259-1 is master
    out #0x21,al
    .word   0x00eb,0x00eb
    mov al,#0x02        ! 8259-2 is slave
    out #0xA1,al
    .word   0x00eb,0x00eb
    mov al,#0x01        ! 8086 mode for both
    out #0x21,al
    .word   0x00eb,0x00eb
    out #0xA1,al
    .word   0x00eb,0x00eb
    mov al,#0xFF        ! mask off all interrupts for now
    out #0x21,al
    .word   0x00eb,0x00eb
    out #0xA1,al

! well, now's the time to actually move into protected mode

	mov ax, #0x0001	! protected mode(PE) bit
	lmsw ax
	jmpi 0, 8 ! jmp offset 0 of the segment 8(cs)


! This routine checks that the keyboard command queue is empty
! No timeout is used - if this hangs there is something wrong
! with the machine, and we probably could not proceed anyway
empty_8042:
	.word 0x00eb, 0x00eb
	in al, #0x64 ! 8042 status port
	test al, #2 ! is input buffer full?
	jnz empty_8042
	ret

gdt:
    .word   0,0,0,0     ! dummy

    .word   0x07FF      ! 8Mb - limit=2047 (2048*4096=8Mb)
    .word   0x0000      ! base address=0
    .word   0x9A00      ! code read/exec
    .word   0x00C0      ! granularity=4096, 386

    .word   0x07FF      ! 8Mb - limit=2047 (2048*4096=8Mb)
    .word   0x0000      ! base address=0
    .word   0x9200      ! data read/write
    .word   0x00C0      ! granularity=4096, 386

idt_48:
    .word   0           ! idt limit=0
    .word   0,0         ! idt base=0L

gdt_48:
    .word   0x800       ! gdt limit=2048, 256 GDT entries
    .word   512+gdt,0x9 ! gdt base = 0X9xxxx

.text
endtext:
.data
enddata:
.bss
ndbss:

