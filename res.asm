.model tiny
.code
org 100h

Start:      call Main

            mov ax, 3100h
            int 21h            ; Exit with memory allocation

;----------------------------------------------------------------------
Main        proc

            call SaveOldHandler

            push 0
            pop es              ; ES -> interrupt vector table
            call NewHandler

            mov dx, offset EndOfProgram
            shr dx, 4
            inc dx              ; keep resident memory = DX * 16

            ret
            endp

;----------------------------------------------------------------------
;Save old interrupt handler address to Old09Ofs and Old09Seg variables
;Arguments: -
;Return value: Old090fs = old handler offset, Old09Seg = old handler segment
;Destroy: AX, BX, ES
;----------------------------------------------------------------------
SaveOldHandler      proc

                    mov ax, 3509h
                    int 21h             ; ES:BX = address of the old interrupt handler

                    mov Old09Ofs, bx
                    mov bx, es
                    mov Old09Seg, bx    ; save old interrupt handler segment and offset to variables

                    ret
                    endp

;----------------------------------------------------------------------
;Write the address of new handler to the interrupt vector table
;Arguments: ES = interrupt vector table address
;Return value: offset of 09h = offset New09, segment of 09h = CS
;Destroy: AX, BX
;----------------------------------------------------------------------
NewHandler          proc

                    cli                         ; disable maskable hardware interrupts
                    mov bx, 09h * 4             ; input offset of interrupt vector table for keyboard to BX
                    mov es:[bx], offset New09   ; input func offset to offset of 09h interrupt vector table

                    mov ax, cs
                    mov es:[bx+2], ax           ; input code segment to segment of 09h interrupt vector table
                    sti                         ; enable maskable hardware interrupts, now the new handler is working

                    ret
                    endp

;----------------------------------------------------------------------
;It's new 09h handler. Output frame with all registers when \ is pressed (43 scan-code). Then returns to old handler.
;Arguments: -
;Return value: -
;----------------------------------------------------------------------
New09       proc
            push sp ax bx cx dx si di bp ds es
            mov bp, sp                  ; now bp -> Stack

            push 0b800h
            pop es                      ; ES -> video memory

            in al, 60h                  ; input to AL from 60h port
            cmp al, 43
            je SkipJump
            jmp Next

SkipJump:   xor bx, bx
            call WriteFrame

            mov bx, 160 * 5 + 30
            mov es: byte ptr[bx], 'E'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 0]
            call HexOutput

            mov bx, 160 * 4 + 30
            mov es: byte ptr[bx], 'D'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 2]
            call HexOutput

            mov bx, 160 * 1 + 30
            mov es: byte ptr[bx], 'B'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'P'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 4]
            call HexOutput

            mov bx, 160 * 6 + 6
            mov es: byte ptr[bx], 'D'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'I'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 6]
            call HexOutput

            mov bx, 160 * 5 + 6
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'I'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 8]
            call HexOutput

            mov bx, 160 * 4 + 6
            mov es: byte ptr[bx], 'D'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'X'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 10]
            call HexOutput

            mov bx, 160 * 3 + 6
            mov es: byte ptr[bx], 'C'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'X'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 12]
            call HexOutput

            mov bx, 160 * 2 + 6
            mov es: byte ptr[bx], 'B'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'X'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 14]
            call HexOutput

            mov bx, 160 * 1 + 6
            mov es: byte ptr[bx], 'A'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'X'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 16]
            call HexOutput

             mov bx, 160 * 2 + 30
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'P'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 18]
            add ax, 6
            call HexOutput

            mov bx, 160 * 9 + 30
            mov es: byte ptr[bx], 'I'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'P'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 20]
            call HexOutput

            mov bx, 160 * 7 + 30
            mov es: byte ptr[bx], 'C'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, [bp + 22]
            call HexOutput

            mov bx, 160 * 6 + 30
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 2
            mov es: byte ptr[bx], 'S'
            mov es: byte ptr[bx+1], 1bh
            add bx, 4
            mov ax, ss
            call HexOutput

Next:       or al, 80h
            out 61h, al                 ; input 1 to leftmost bit of 61h

            and al, not 80h
            out 61h, al                 ; input 0 to leftmost bit of 61h
                                        ; signal that the interrupt has been processed
            mov al, 20h
            out 20h, al                 ; input code 20h to interrupt controller
                                        ; end of interrupt
            pop es ds bp di si dx cx bx ax sp
            db 0eah
            Old09Ofs dw 0
            Old09Seg dw 0               ; return to old interrupt handler
            endp

;-------------------------------------------------------------------
;Converts a binary number to hexadecimal and output it
;Arguments: AX = binary number to convert, ES -> video memory segment, BX = address on screen
;Return value: AX = binary number to convert
;Destroy: BX
;-------------------------------------------------------------------
HexOutput               proc

                        push ax

                        shr ah, 4                   ; AH = first symbol value in hex
                        cmp ah, 9
                        jg IfAH_Letter1
                        jle IfAH_Number1
Next1:                  mov es: byte ptr[bx], ah
                        mov es: byte ptr[bx+1], 1bh
                        add bx, 2

                        pop ax
                        push ax
                        and ah, 0Fh
                        cmp ah, 9
                        jg IfAH_Letter2
                        jle IfAH_Number2
Next2:                  mov es: byte ptr[bx], ah
                        mov es: byte ptr[bx+1], 1bh
                        add bx, 2

                        pop ax
                        push ax
                        shr al, 4
                        cmp al, 9
                        jg IfAL_Letter1
                        jle IfAL_Number1
Next3:                  mov es: byte ptr[bx], al
                        mov es: byte ptr[bx+1], 1bh
                        add bx, 2

                        pop ax
                        push ax
                        and al, 0Fh
                        cmp al, 9
                        jg IfAL_Letter2
                        jle IfAL_Number2
Next4:                  mov es: byte ptr[bx], al
                        mov es: byte ptr[bx+1], 1bh
                        add bx, 2

                        jmp EndFunc

IfAH_Number1:           add ah, '0'
                        jmp Next1

IfAH_Letter1:           add ah, 'A'
                        sub ah, 10
                        jmp Next1

IfAH_Number2:           add ah, '0'
                        jmp Next2

IfAH_Letter2:           add ah, 'A'
                        sub ah, 10
                        jmp Next2

IfAL_Number1:           add al, '0'
                        jmp Next3

IfAL_Letter1:           add al, 'A'
                        sub al, 10
                        jmp Next3

IfAL_Number2:           add al, '0'
                        jmp Next4

IfAL_Letter2:           add al, 'A'
                        sub al, 10
                        jmp Next4

EndFunc:                pop ax

                        ret
                        endp


;----------------------------------------------------------------------
;Write frame on the screen
;Arguments: BX = frame address on screen
;Return value: -
;Destroy: AX, BX
;----------------------------------------------------------------------
WriteFrame      proc

                mov cx, 24              ; Set number of symbols in string
                mov si, cx
                sub si, 2
                call WriteTopLine

		        xor bx, bx	            ; BX is now frame address
		        mov cx, 9 	            ; Set number of lines
		        call WritePillars

		        add bx, 160 	        ; BX = Bottom line of frame address
		        call WriteBottomLine

		        ret
		        endp

;-------------------------------------------------------------------------------------------
;Write top horizontal line of frame on screen
;Arguments: BX = Frame address on screen, CX = number of symbols in string
;Return value: CX = 0
;Destroy: AX, BX
;-------------------------------------------------------------------------------------------
WriteTopLine    proc

                sub cx, 2
		        mov al, 0c9h
		        mov ah, 1bh
		        mov es:[bx], ax                 ; Write top left symbol of frame
		        add bx, 2

TopLine:        mov es: byte ptr[bx], 0cdh	    ; Write horizontal symbols cycle
		        mov es: byte ptr[bx+1], 1bh
		        add bx, 2
		        loop TopLine

		        mov al, 0bbh
		        mov ah, 1bh
		        mov es:[bx], ax                 ; Write top right symbol of frame

		        ret
		        endp

;-------------------------------------------------------------------------------------------
;Write pillars of frame and fill frame
;Arguments: BX = Frame address on screen, SI = Number of horizontal symbols in frame string, CX = number of lines
;Return value: BX = address of the last filled line
;              SI = Number of horizontal symbols in frame string, CX = 0
;Destroy: -
;-------------------------------------------------------------------------------------------
WritePillars   	proc

Pillars:	    push si
                add bx, 160	                            ; BX = New string address
		        push bx
		        mov es: byte ptr[bx], 0bah
		        mov es: byte ptr[bx+1], 1bh	            ; Write first pillar's symbol in string
		        add bx, 2

FillScreen: 	mov es: byte ptr[bx+1], 1bh
    		    add bx, 2
		        dec si
		        cmp si, 0
		        jg FillScreen

		        mov es: byte ptr[bx], 0bah
		        mov es: byte ptr[bx+1], 1bh             ; Write second pillar's symbol in string

		        pop bx
		        pop si
		        loop Pillars

		        ret
		        endp

;-------------------------------------------------------------------------------------------
;Write bottom horizontal line of frame on screen
;Arguments: BX = Bottom line of frame address, SI = Number of horizontal symbols in frame string
;Return value: 	SI = Number of horizontal symbols in frame string, CX = 0
;Destroy: AX, BX
;-------------------------------------------------------------------------------------------
WriteBottomLine         proc

		                mov al, 0c8h
		                mov es:[bx], ax
		                add bx, 2                       ; Write bottom left symbol of frame

		                mov cx, si

BottomLine:             mov es: byte ptr[bx], 0cdh
		                mov es: byte ptr[bx+1], 1bh
		                add bx, 2
		                loop BottomLine

		                mov al, 0bch
		                mov ah, 1bh
		                mov es:[bx], ax                 ; Write bottom right symbol of frame

		                ret
		                endp

EndOfProgram:
end         Start
