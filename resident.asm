.model tiny
.code
org 100h

;----------------------------------------------------------------------
; Save old int_num interrupt handler address to old_ofs and old_seg variables
; Arguments: -
; Return value: old_ofs = old handler offset, old_seg = old handler segment
; Destroy: AX, BX, ES
;----------------------------------------------------------------------
SAVE_OLD_INT   macro int_num, old_ofs, old_seg
               mov ax, 3500h + int_num
               int 21h

               mov old_ofs, bx
               mov bx, es
               mov old_seg, bx
               endm

;----------------------------------------------------------------------
; Write the address of new int_num handler to the interrupt vector table
; Arguments: ES = interrupt vector table address
; Return value: offset of int_num = offset new_handler, segment of int_num = CS
; Destroy: AX, BX
;----------------------------------------------------------------------
SET_NEW_INT    macro int_num, new_handler
               cli
               push 0
               pop es

               mov bx, int_num * 4
               mov es:[bx], offset new_handler
               mov ax, cs
               mov es:[bx+2], ax
               sti
               endm

;----------------------------------------------------------------------
; Output 2-letter register name at ES:[BX]
; Arguments: ch1 = first reg name character, ch2 = second reg name character, ES = 0b800h
; Return value: BX -> screen position in video memory
;----------------------------------------------------------------------
PUT_NAME    macro ch1, ch2
            mov es:byte ptr [bx], ch1   
            mov es:byte ptr [bx+1], 1bh
            add bx, 2
            mov es:byte ptr [bx], ch2
            mov es:byte ptr [bx+1], 1bh
            add bx, 4
            endm

;----------------------------------------------------------------------
; Output register value on screen.
; Arguments:    row, col = screen position
;               ch1, ch2 = register name letters
;               value = value loaded into AX
; Return value: -
; Destroy: BX, DX
;----------------------------------------------------------------------
PUT_REG     macro row, col, ch1, ch2, value
            mov bx, 160 * row + col
            PUT_NAME ch1, ch2
            mov ax, value
            call HexOutput
            endm

;----------------------------------------------------------------------
; Output register name, assuming AX already contains the value
; Arguments:    row, col = screen position
;               ch1, ch2 = register name letters
; Return value: -
; Destroy: BX, DX
;----------------------------------------------------------------------
PUT_REG_AX  macro row, col, ch1, ch2
            mov bx, 160 * row + col
            PUT_NAME ch1, ch2
            call HexOutput
            endm

;----------------------------------------------------------------------
Start:      call Main

            mov ax, 3100h
            int 21h            ; Exit with memory allocation

;----------------------------------------------------------------------
Main        proc

            SAVE_OLD_INT 08h, Old08Ofs, Old08Seg
            SAVE_OLD_INT 09h, Old09Ofs, Old09Seg
            SET_NEW_INT  08h, New08
            SET_NEW_INT  09h, New09

            mov dx, offset EndOfProgram
            shr dx, 4
            inc dx              ; keep resident memory = DX * 16

            ret
            endp

;----------------------------------------------------------------------
; It's new 08h handler. If ShowFlag == 1, redraw frame with registers.
; Arguments: -
; Return value: -
;----------------------------------------------------------------------
New08       proc
            push sp ax bx cx dx si di bp ds es

            cmp ShowFlag, 1
            je DrawRegs
            jmp SkipDraw

DrawRegs:   mov bp, sp                  ; now bp -> Stack
            push 0b800h
            pop es                      ; ES -> video memory

            xor bx, bx
            call WriteFrame

            PUT_REG 5, 30, 'E', 'S', <[bp + 0]>
            PUT_REG 4, 30, 'D', 'S', <[bp + 2]>
            PUT_REG 1, 30, 'B', 'P', <[bp + 4]>

            PUT_REG 6,  6, 'D', 'I', <[bp + 6]>
            PUT_REG 5,  6, 'S', 'I', <[bp + 8]>
            PUT_REG 4,  6, 'D', 'X', <[bp + 10]>
            PUT_REG 3,  6, 'C', 'X', <[bp + 12]>
            PUT_REG 2,  6, 'B', 'X', <[bp + 14]>
            PUT_REG 1,  6, 'A', 'X', <[bp + 16]>

            mov ax, [bp + 18]
            add ax, 6
            PUT_REG_AX 2, 30, 'S', 'P'

            PUT_REG 9, 30, 'I', 'P', <[bp + 20]>
            PUT_REG 7, 30, 'C', 'S', <[bp + 22]>

            mov ax, ss
            PUT_REG_AX 6, 30, 'S', 'S'

SkipDraw:   pop es ds bp di si dx cx bx ax sp
            db 0eah
            Old08Ofs dw 0
            Old08Seg dw 0
            endp

;----------------------------------------------------------------------
; It's new 09h handler. Set ShowFlag to 1 if \ is pressed.
; Arguments: -
; Return value: -
;----------------------------------------------------------------------
New09               proc
                    push ax

                    in al, 60h
                    cmp al, 43          ; cmp al with \ code
                    jne PassToOld09
                    xor ShowFlag, 1

PassToOld09:        or al, 80h
                    out 61h, al         ; input 1 to leftmost bit of 61h
                    and al, not 80h
                    out 61h, al         ; input 0 to leftmost bit of 61h, signal that the interrupt has been processed
                    mov al, 20h
                    out 20h, al         ; input code 20h to interrupt controller
                    pop ax
                    db 0eah
                    Old09Ofs dw 0
                    Old09Seg dw 0
                    endp

;-------------------------------------------------------------------
; Converts value 0..F in AL to hex ASCII symbol and outputs it
; Arguments: AL = hex digit value, ES -> video memory, BX = screen address
; Return value: BX = next screen position
; Destroy: AL, BX
;-------------------------------------------------------------------
HexDigitOutput      proc

                    cmp al, 9
                    jbe HexDigitNumber
                    add al, 'A' - 10
                    jmp HexDigitWrite

HexDigitNumber:     add al, '0'

HexDigitWrite:      mov es: byte ptr[bx], al
                    mov es: byte ptr[bx+1], 1bh
                    add bx, 2

                    ret
                    endp

;-------------------------------------------------------------------
; Converts a binary number to hexadecimal and outputs it
; Arguments: AX = binary number to convert, ES -> video memory segment, BX = address on screen
; Return value: AX = binary number to convert
; Destroy: BX, DX
;-------------------------------------------------------------------
HexOutput           proc

                    push ax
                    mov dx, ax

                    mov al, dh
                    shr al, 4
                    call HexDigitOutput     ; first number

                    mov al, dh
                    and al, 0Fh
                    call HexDigitOutput     ; second number

                    mov al, dl
                    shr al, 4
                    call HexDigitOutput     ; third number

                    mov al, dl
                    and al, 0Fh
                    call HexDigitOutput     ; fourth number

                    pop ax
                    ret
                    endp

;----------------------------------------------------------------------
; Write frame on the screen
; Arguments: BX = frame address on screen
; Return value: -
; Destroy: AX, BX
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
; Write top horizontal line of frame on screen
; Arguments: BX = Frame address on screen, CX = number of symbols in string
; Return value: CX = 0
; Destroy: AX, BX
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
; Write pillars of frame and fill frame
; Arguments: BX = Frame address on screen, SI = Number of horizontal symbols in frame string, CX = number of lines
; Return value: BX = address of the last filled line
;               SI = Number of horizontal symbols in frame string, CX = 0
; Destroy: -
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
; Write bottom horizontal line of frame on screen
; Arguments: BX = Bottom line of frame address, SI = Number of horizontal symbols in frame string
; Return value: SI = Number of horizontal symbols in frame string, CX = 0
; Destroy: AX, BX
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

;-------------------------------------------------------------------------------------------
ShowFlag db 0

EndOfProgram:
end         Start
