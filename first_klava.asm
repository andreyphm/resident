.model tiny
.code
org 100h

Start:      push 0b800h
            pop es      ; ES -> video memory

            mov bx, (5*80d + 40d) * 2   ; BX = address of 5th string's center
            mov ah, 1eh     ; set color

Next:       in al, 60h      ; input to AL from 60h port
            mov es:[bx], ax

            cmp al, 1
            jne Next    ; While input is not ESC continue

            mov ax, 4c00h
            int 21h         ; Exit

end         Start



