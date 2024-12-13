.code
ifndef __WINDOW_INC__
__WINDOW_INC__:

INCLUDE csfml.inc
INCLUDE box2d.inc
INCLUDE draw.asm
INCLUDE entity.asm
INCLUDE world.asm

.data
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
    ALIGNED_LOCAL window_ptr,sfPtr
    sub rsp, 32 ; shadow space
    
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
    mov window_ptr,rax    ; store window ptr on stack

    ; set frame limit
    mov rcx, rax
    mov rdx, 60
    call sfRenderWindow_setFramerateLimit

    mov rax,window_ptr ; return window ptr in rax

    add rsp, 32 ; shadow space
    ret
bwCreateWindow ENDP

; Process window messages
bwProcessMessages PROC
    ALIGNED_LOCAL data,bwWorldData
    sub rsp, 32 ; shadow space
;     mov has_event,false
; poll:
;     mov rcx, window
;     lea rdx, event
;     call sfRenderWindow_pollEvent
;     test al, al
;     jz break
;     mov has_event,true
; 
;     cmp event._type, sfEvtClosed
;     jne not_closed
;     mov rcx, window
;     call sfRenderWindow_close
;     jmp poll
; not_closed:
; 
;     cmp event._type, sfEvtKeyReleased
;     jne not_keyup
;     mov ecx, event.key._code
;     call bwProcessKeyUp
;     jmp poll
; not_keyup:
; 
;     cmp event._type, sfEvtMouseButtonReleased
;     jne not_mouseup
;     lea rcx, event.mouseButton
;     call bwProcessMouseUp
;     jmp poll
; not_mouseup:
; 
;     jmp poll
; break:
; 
;     lea r8,event
;     mov al,has_event
;     test al,al
;     jnz process_events
;     mov r8,0
; process_events:
    mov ecx,timeStep
    mov data.timeStep,ecx
    mov ecx,worldId
    mov data.worldId,ecx
    mov rcx, window
    mov data.pWindow,rcx
    mov rcx,pView
    mov data.pView,rcx
    lea rcx,renderStates
    mov data.pRenderStates,rcx
    lea rcx,entities_pool
    mov data.pEntityPool,rcx
    mov data.pParticlePool,0

    lea rcx, data
    call bwProcessEvents

    add rsp, 32 ; shadow space
    ret
bwProcessMessages ENDP

; KeyUp handler
; RCX key:sfKey
; bwProcessKeyUp PROC
;     sub rsp, 40 ; shadow space
; 
;     cmp ecx, sfKeyEnter
;     jne not_enter
;     ; Create box
;     
;     mov rcx, boxHalfSize
;     mov rdx, boxPos
;     mov r8d, b2_dynamicBody
;     call bwCreateBox
; 
;     lea rcx, entities_pool
;     mov rdx, rax
;     call bwEntity_CreateDefault
; 
;     mov rcx, pSprite
;     mov sfPtr PTR [rax][bwEntity.pSprite],rcx
; 
;     ; Apply torque to box
;     mov rcx, b2BodyId PTR [rax]
;     movss xmm1, torque
;     mov r8, 1
;     call b2Body_ApplyTorque
;     jmp break
; not_enter:
; 
;     cmp ecx, sfKeySpace
;     jne not_space
; 
;     ; Create explosion
; 
;     ; Find mouse position
;     mov rcx,window
;     call sfMouse_getPositionRenderWindow
; 
;     mov rcx,window
;     mov rdx, rax
;     mov r8, pView
;     call sfRenderWindow_mapPixelToCoords
; 
;     mov rcx, rax
;     mov rdx, 041200000h ;10.0
;     movd xmm1,rdx
;     call bwCreateExplosion
; 
;     jmp break
; not_space:
; 
; break:
; 
;     add rsp, 40 ; shadow space
;     ret
; bwProcessKeyUp ENDP
; 
; ; RCX:ptr sfMouseButtonEvent
; bwProcessMouseUp PROC
;     ALIGNED_LOCAL button,DWORD
;     sub rsp, 32 ; shadow space
;     
;     mov eax,DWORD PTR [rcx][sfMouseButtonEvent.button]
;     mov button,eax
;     
;     ; Map coord to world
;     mov rdx, QWORD PTR [rcx][sfMouseButtonEvent.x]
;     mov rcx, window
;     mov r8, pView
;     call sfRenderWindow_mapPixelToCoords
;     ; Coord now stored in rax
;     
;     mov ecx,button
;     cmp ecx,sfMouseLeft
;     jne not_left
;     mov rcx, boxHalfSize
;     mov rdx, rax
;     mov r8d, b2_dynamicBody
;     call bwCreateBox
; 
;     lea rcx, entities_pool
;     mov rdx, rax
;     call bwEntity_CreateDefault
; 
;     mov rcx, pSprite
;     mov sfPtr PTR [rax][bwEntity.pSprite],rcx
;     
; 	mov float PTR [rax][bwEntity.timeLeft],040a00000h ; 5.
; 	mov float PTR [rax][bwEntity.explosionStrength],040a00000h ; 5.
; 	mov uint32_t PTR [rax][bwEntity.explosionParts],20
;     jmp break
; 
; not_left:
;     movss xmm0, ball_radius
;     mov rdx, rax
;     mov r8d, b2_dynamicBody
;     call bwCreateBall
;         
;     lea rcx, entities_pool
;     mov rdx, rax
;     call bwEntity_CreateDefault
; 
;     mov rcx, pSprite
;     mov sfPtr PTR [rax][bwEntity.pSprite],rcx
;     jmp break
;     
; 
; break:
; 
;     add rsp, 32 ; shadow space
;     ret
; bwProcessMouseUp ENDP

endif