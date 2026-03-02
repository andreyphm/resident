.model tiny
.code
org 100h

Start:      call Main

;----------------------------------------------------------------------
Main        proc

            cli
            mov ax, 0009h
            mov ds, ax
            mov ax, 0010h
            mov es, ax
            mov ax, 0011h
            mov ss, ax

            mov ax, 0001h
            mov bx, 0002h
            mov cx, 0003h
            mov dx, 0004h
            mov si, 0005h
            mov di, 0006h

            mov bp, 0007h
            mov sp, 0008h
            sti

InfLoop:    jmp InfLoop

            ret
            endp

end         Start
