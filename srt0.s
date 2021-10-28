; onyx bootloader, rewrite 6
org 0x7c00
bits 16

global start

start:
        mov sp, 0x7c00
        mov word [dap.block_count], 0x04        ; 4 blocks
        mov word [dap.buffer_offset], main      ; label is right after block 1
        mov word [dap.buffer_segment], 0x0000   ; segment 0
        mov word [dap.lba_value], 0x01          ; read one sector
        call readDisk

        mov ax, [superblock + 56]       ; read ext2 magic
        cmp ax, 0xef53                  ; see if its correct
        je main				; if it is jump to main
	mov ax, 0xdead
	cli
	hlt


; dap must be filled in
readDisk:
	push edx
        mov dl, 0x80    ; disk to read from
        mov si, dap     ; load address of dap to si
        mov ah, 0x42    ; this function read from disk using lba
        int 0x13        ; call bios
	pop edx
        ret             ; return to caller


dap:
        .packet_size            db 0x10         ; ignore
        .reserved               db 0x00         ; ignore
        .block_count            dw 0x00
        .buffer_offset          dw 0x00
        .buffer_segment         dw 0x00
        .lba_value              dq 0x00         ; dont load with qword

align 2
name1 db "boot", 0x00, 0x00, 0x00, 0x00		; len 8, 
name2 db "loader", 0x00, 0x00 			; len 8
; names in directory entries are aligned on 4 byte boundries so we pad to the
; nearest 4 bytes

align 16
; global descriptor table, simple enough to get us to pm, we can change it later
gdt:

gdt_null:
	dq 0x00

gdt_code:
	dw 0xffff		; segment limiter bits 0-15
	dw 0x00			; base segment bits 0-15 

	db 0x00			; base segment bits 16-23
	db 0x9a			; type, privilege level, and present flag
	db 0xcf			; limit 16-19, attributes, granularity
	db 0x00			; base segment bits 24-31

gdt_data:
	dw 0xffff		; segment limiter bits 0-15
	dw 0x00			; base segment bits 0-15 

	db 0x00			; base segment bits 16-23
	db 0x92			; type, privilege level, and present flag
	db 0xcf			; limit 16-19, attributes, granularity
	db 0x00			; base segment bits 24-31

gdt_end:

gdt_desc:
	dw gdt_end - gdt
	dd gdt

times 510 - ($-$$) db 0x00      ; pad program with zeros so that boot
dw 0xaa55                       ; signiture is at end of boot block


main:
	mov eax, 0x2		; inode of root directory
	call readInode		; get root entry

	lea di, 0x1000		; where we start looking
	lea si, name1		; string we looking for
	mov cx, 0x400		; search first 400 bytes
	mov dx, 0x08		; length of string
	call findName		; di contains addr of first byte of name
	mov eax, [di - 8]	; extract inode number from entry

	call readInode		; read directory entry
	
	lea di, 0x1000
	lea si, name2
	mov cx, 0x400
	mov dx, 0x08
	call findName
	mov eax, [di - 8]	; extract inode number from entry

	call readInode		; read loader from disk

	jmp jump32		; enable 32 bit mode


; eax: inode
readInode:
findBlockGroup:
	dec eax				; subtract one
	mov ebx, [superblock + 40]	; ebx = inodes per block group
	xor dx, dx
	div ebx				; inode / inodes per block group
	push edx			; push 2
readBlockGroup:
	mov ebx, 0x10			; 16 decimal
	xor edx, edx
	div ebx				; blockgroup / 16
	imul edx, 0x20			; dx * 32
	add eax, 0x04			; block group entries start on block 5
	mov dword [dap.lba_value], eax	; block 
	mov word [dap.buffer_offset], 0x1000
	mov word [dap.block_count], 0x01
	call readDisk
readInodeTable:
	mov eax, [0x1000 + edx + 8]	; block containing inode table
	imul eax, 0x02			; 1024 block to 512 blocks
	pop ebx				; pop 2, index
	push eax			; push 3, first block of table
	mov eax, ebx			; move index to ax
	mov ebx, 0x02			; mov bx 2
	xor edx, edx			; clear dx
	div ebx				; index / 2
	mov ebx, eax
	pop eax				; pop 3
	add eax, ebx
	imul edx, 0x100
	mov dword [dap.lba_value], eax
	mov word [dap.block_count], 0x01
	call readDisk
	lea di, [0x1000 + edx + 40]	; addr of first block pointer of inode
	mov eax, [0x1000 + edx + 28]
	mov ebx, 0x1000
readBlocks:
	mov ecx, [di]
	imul ecx, 0x02
	mov dword [dap.lba_value], ecx
	mov dword [dap.buffer_offset], ebx
	mov word [dap.block_count], 0x02
	call readDisk
	add di, 0x04
	add ebx, 0x0400
	sub eax, 0x02
	jnz readBlocks
	ret


; di: where to look
; si: string to look for
; cx: how far to look before stopping
; dx: length of string to look for
; this is a very simple, brute force string finder, use with caution
findName:
	xor ebx, ebx


fNloop:
	mov ax, [di]
	cmp ax, [si]
	jz fNfound


fNnotFound:
	add di, 0x02
	xor ebx, ebx
	sub cx, 0x02
	cmp bx, cx
	jnz fNloop
	mov ax, 0x0f00
	ret


fNfound:
	add di, 0x02
	add si, 0x02
	add bx, 0x02
	sub cx, 0x02
	cmp bx, dx
	jnz fNloop
	sub di, dx
	ret


jump32:
	cli
; enable a20	
	in al, 0x92
	or al, 2
	out 0x92, al

	xor ax, ax
	mov ds, ax

	lgdt [gdt_desc]

	mov eax, cr0
	or eax, 0x01
	mov cr0, eax
	jmp 0x08:leave

bits 32
leave:
	mov ax, 0x10
	mov ds, ax
	mov ss, ax
	mov esp, 0x90000
	jmp 0x08:0x1000
	hlt
	jmp leave


times 1024 - ($-$$) db 0x00
superblock:
