.code
ifndef __WINDOW_INC__
__WINDOW_INC__:

INCLUDE csfml.inc
INCLUDE box2d.inc
INCLUDE draw.asm
INCLUDE entity.asm

.data
window_event sfEvent <>
window_contextSettings sfContextSettings <>
window_videoMode sfVideoMode <>
font QWORD 0
fps_text QWORD 0
ball_radius float 2.

.code
; parameters
; ecx, window_width
; edx, window_height
; r8, window_title

bwCreateWindow PROC
    sub rsp, 40 ; shadow space
    
    ; set up gl context with anti-aliasing
    mov window_contextSettings.depthBits, 0
    mov window_contextSettings.stencilBits, 0
    mov window_contextSettings.antialiasingLevel, 4
    mov window_contextSettings.majorVersion, 1
    mov window_contextSettings.minorVersion, 1
    mov window_contextSettings.attributeFlags, 0
    lea rax, window_contextSettings.sRgbCapable
    mov [rax], DWORD PTR 0

    ; set up video mode
    mov window_videoMode._width, ecx
    mov window_videoMode.height, edx
    mov window_videoMode.bitsPerPixel, 32

    ; create window
    lea rcx, window_videoMode
    mov rdx, r8
    mov r8, 5 ; sfTitlebar | sfClose
    lea r9, window_contextSettings
    call sfRenderWindow_create
    mov [rsp+40+40],rax    ; store window ptr on stack

    ; set frame limit
    mov rcx, rax
    mov rdx, 60
    call sfRenderWindow_setFramerateLimit

    mov rax,[rsp+40+40] ; return window ptr in rax

    add rsp, 40 ; shadow space
    ret
bwCreateWindow ENDP

; Process window messages
bwProcessMessages PROC
    sub rsp, 40 ; shadow space
poll:
    mov rcx, window
    lea rdx, window_event
    call sfRenderWindow_pollEvent
    cmp al, 0
    jz break

    cmp window_event._type, sfEvtClosed
    jnz not_closed
    mov rcx, window
    call sfRenderWindow_close
    jmp break
not_closed:

    cmp window_event._type, sfEvtKeyReleased
    jnz not_keyup
    mov ecx, window_event.key._code
    call bwProcessKeyUp
    jmp break
not_keyup:


    cmp window_event._type, sfEvtMouseButtonReleased
    jnz not_mouseup
    lea rcx, window_event.mouseButton
    call bwProcessMouseUp
    jmp break
not_mouseup:
    
    jmp poll

break:
    add rsp, 40 ; shadow space
    ret
bwProcessMessages ENDP

; KeyUp handler
; RCX key:sfKey
bwProcessKeyUp PROC
    sub rsp, 40 ; shadow space

    cmp ecx, sfKeySpace
    jnz break
    ; Create box
    
    mov rcx, boxHalfSize
    mov rdx, boxPos
    mov r8d, b2_dynamicBody
    call bwCreateBox

    mov rcx, rax
    mov rdx, pSprite
    call bwEntity_Create

    ; Apply torque to box
    mov rcx, b2BodyId PTR [rax]
    movss xmm1, torque
    mov r8, 1
    call b2Body_ApplyTorque
break:

    add rsp, 40 ; shadow space
    ret
bwProcessKeyUp ENDP

; RCX:ptr sfMouseButtonEvent
button$ = 40+32
bwProcessMouseUp PROC

    sub rsp, 40 ; shadow space
    
    mov eax,DWORD PTR [rcx][sfMouseButtonEvent.button]
    mov button$[rsp],eax
    
    ; Map coord to world
    mov rdx, QWORD PTR [rcx][sfMouseButtonEvent.x]
    mov rcx, window
    mov r8, pView
    call sfRenderWindow_mapPixelToCoords
    ; Coord now stored in rax
    
    mov ecx,button$[rsp]
    cmp ecx,sfMouseLeft
    jne not_left
    mov rcx, boxHalfSize
    mov rdx, rax
    mov r8d, b2_dynamicBody
    call bwCreateBox
    mov rcx, rax
    mov rdx, pSprite
    call bwEntity_Create
    jmp break

not_left:
    movss xmm0, ball_radius
    mov rdx, rax
    mov r8d, b2_dynamicBody
    call bwCreateBall
    jmp break
    

break:

    add rsp, 40 ; shadow space
    ret
bwProcessMouseUp ENDP

endif