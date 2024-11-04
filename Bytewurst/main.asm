; Static linked C and C++ runtime libraries
; INCLUDELIB libucrt.lib
; INCLUDELIB libvcruntime.lib
; INCLUDELIB libcmt.lib
; INCLUDELIB libcpmt.lib

; Debug version
; INCLUDELIB libucrtd.lib
; INCLUDELIB libvcruntimed.lib
; INCLUDELIB libcmtd.lib
; INCLUDELIB libcpmtd.lib

INCLUDELIB csfml-audio.lib
INCLUDELIB csfml-graphics.lib
INCLUDELIB csfml-network.lib
INCLUDELIB csfml-system.lib
INCLUDELIB csfml-window.lib

bwPtr EQU <QWORD>

option casemap:none

ExitProcess PROTO
OutputDebugStringA PROTO
malloc PROTO
memcpy PROTO
memset PROTO
memmove PROTO

OutputDebugString TEXTEQU <OutputDebugStringA>

INCLUDE stdtypes.inc
INCLUDE box2d.inc
INCLUDE csfml.inc

.data
window_title BYTE 'AssemgryBird!', 0
window QWORD ?
window_background DWORD 0
window_width EQU 1280
window_height EQU 720

timeStep float 0.016666666666666666
worldId DWORD ?
worldDef b2WorldDef <>

groundHalfSize b2Vec2 <50., 10.>
groundPos b2Vec2 <0.,-10.>

boxHalfSize b2Vec2 <2., 2.>
boxPos b2Vec2 <0., 10.>

torque float 50.

INCLUDE world.asm
INCLUDE window.asm

.code
main PROC
    sub     rsp, 4*8+8 ; allocate shadow space

    call bwSetup
    
    ; Create window
    mov rcx, window_width
    mov rdx, window_height
    lea r8, window_title
    call bwCreateWindow
    mov window, rax

    ; Create world def
    lea rcx, worldDef
    call b2DefaultWorldDef

    ; Create world using default def
    lea rcx, worldDef
    call b2CreateWorld
    mov worldId, eax

    ; Create ground
    mov rcx, groundHalfSize
    mov rdx, groundPos
    mov r8d, b2_staticBody
    call bwCreateBox

; Main window message loop
window_loop:

    ; clear the window with black color
    mov rcx, window
    mov edx, window_background
    call sfRenderWindow_clear

    ; Simulate world
    mov ecx, worldId
    movd xmm1, timeStep
    mov r8, 4
    call b2World_Step

    ; debug draw
    mov rcx, window
    mov edx, worldId
    call bwDrawWorld

    call bwWorld_Draw

    ; Process messages, including inputs
    call bwProcessMessages

    ; display window
    mov rcx, window
    call sfRenderWindow_display
    
    ; check if window is open. Break the loop if not
    mov rcx, window
    call sfRenderWindow_isOpen
    cmp al, 0
    jnz window_loop
    
    mov ecx, worldId
    call b2DestroyWorld

    xor     rcx, rcx
    call    ExitProcess

    add     rsp, 4*8+8 ; pop shadow space
    ret
main ENDP
END