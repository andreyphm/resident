.model tiny
.code
org 100h

Start:      mov ax, 3509h
            int 21h
            mov Old09Ofs, bx
            mov bx, es
            mov Old09Seg, bx

            push 0
            pop es      ; ES -> interrupt vector table

            cli         ; disable maskable hardware interrupts
            mov bx, 09h * 4     ; input offset of interrupt vector table for keyboard to BX
            mov es:[bx], offset New09   ; input func offset to offset of 09h interrupt vector table

            mov ax, cs
            mov es:[bx+2], ax       ; input code segment to segment of 09h interrupt vector table
            sti         ; enable maskable hardware interrupts

            mov dx, offset EndOfProgram
            shr dx, 4
            inc dx      ; keep resident memory = DX * 16

            mov ax, 3100h      ; save exit code
            int 21h            ; Exit

New09       proc
            push ax bx es

            push 0b800h
            pop es      ; ES -> video memory

            mov bx, (5*80d + 40d) * 2   ; BX = address of 5th string's center
            mov ah, 1eh     ; set color

            in al, 60h      ; input to AL from 60h port
            mov es:[bx], ax

            in al, 60h
            or al, 80h
            out 61h, al     ; input 1 to leftmost bit of 61h

            and al, not 80h
            out 61h, al     ; input 0 to leftmost bit of 61h

            mov al, 20h
            out 20h, al     ; input code 20h to interrupt controller

            pop es bx ax
            db 0eah
            Old09Seg dw 0
            Old09Ofs dw 0
            endp

EndOfProgram:
end         Start



