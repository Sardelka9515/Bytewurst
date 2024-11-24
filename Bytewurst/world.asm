.code
ifndef __WORLD_INC__
__WORLD_INC__:

INCLUDE box2d.inc
INCLUDE draw.asm
INCLUDE entity.asm
INCLUDE pool.asm

.data

defaultFriction float 0.3
defaultRestitution float 0.5
defaultDensity float 1.

newBodyDef b2BodyDef <>
newBodyId b2BodyId <>
newShapeDef b2ShapeDef <>
newPos b2Vec2 <0., 0.>

newHalfSize b2Vec2 <50., 10.>
newRadius float 0.

newBox b2Polygon <>
newBall b2Circle <>

entities_pool bwPool <0>

.code

; RCX halfSize:b2Vec2
; RDX pos:b2Vec2
; R8 bodyType:b2int
; Returns bodyId:b2BodyId
; Create a static or dynamic box
bwCreateBox PROC
    sub rsp, 4*8+8 ; allocate shadow space

    mov [rsp+32],rcx
    mov [rsp+24],rdx
    mov [rsp+16],r8

    ; Create ground body def
    lea rcx, newBodyDef
    call b2DefaultBodyDef

    
    ; set body type
    mov eax, [rsp+16]
    mov newBodyDef._type, eax

    ; set body position
    mov rax, [rsp+24]
    mov newBodyDef.position, rax

    ; Create new body
    mov ecx, worldId
    lea rdx, newBodyDef
    call b2CreateBody
    mov newBodyId, rax

    ; Create new box
    lea rcx, newBox
    movss xmm1, REAL4 PTR [rsp+32]
    mov rax,[rsp+32]
    shr rax, 32
    movd xmm2, eax

    call b2MakeBox

    ; Create box shape
    lea rcx, newShapeDef
    call b2DefaultShapeDef

    ; Set shape parameters
    mov eax, defaultFriction
    mov newShapeDef.friction, eax
    mov eax, defaultRestitution
    mov newShapeDef.restitution, eax
    mov eax, defaultDensity
    mov newShapeDef.density, eax

    mov rcx, newBodyId
    lea rdx, newShapeDef
    lea r8, newBox
    call b2CreatePolygonShape

    mov rax, newBodyId

    add rsp, 40 ; pop shadow space
    ret
bwCreateBox ENDP


; XMM0 radius:float
; RDX pos:b2Vec2
; R8 bodyType:b2int
; Returns bodyId:b2BodyId
; Create a static or dynamic ball
bwCreateBall PROC
    sub rsp, 4*8+8 ; allocate shadow space

    mov [rsp+24],rdx
    mov [rsp+16],r8

    
    ; Set circle params
    mov b2Vec2 PTR newBall.center,0
    movss float PTR newBall.radius,XMM0
    
    ; Create ground body def
    lea rcx, newBodyDef
    call b2DefaultBodyDef

    
    ; set body type
    mov eax, [rsp+16]
    mov newBodyDef._type, eax

    ; set body position
    mov rax, [rsp+24]
    mov newBodyDef.position, rax

    ; Create new body
    mov ecx, worldId
    lea rdx, newBodyDef
    call b2CreateBody
    mov newBodyId, rax

    ; Create shape
    lea rcx, newShapeDef
    call b2DefaultShapeDef

    ; Set shape parameters
    mov eax, defaultFriction
    mov newShapeDef.friction, eax
    mov eax, defaultRestitution
    mov newShapeDef.restitution, eax
    mov eax, defaultDensity
    mov newShapeDef.density, eax

    mov rcx, newBodyId
    lea rdx, newShapeDef
    lea r8, newBall
    call b2CreateCircleShape

    mov rax, newBodyId

    add rsp, 40 ; pop shadow space
    ret
bwCreateBall ENDP

; RCX pos:b2Vec2
; XMM1 radius:float
bwCreateExplosion PROC
    LOCAL pos:b2Vec2
    LOCAL def:b2ExplosionDef
    sub rsp, 4*8+8 ; allocate shadow space

    mov def.position, rcx
    movd def.radius,xmm1
    mov def.impulsePerLength, 42480000h ;50.0
    mov def.falloff,40a00000h  ;5.0
    mov def.maskBits,0ffffffffffffffffh

    mov ecx,worldId
    lea rdx, def
    call b2World_Explode

    add rsp, 40 ; pop shadow space
    ret
bwCreateExplosion ENDP

bwWorld_Draw PROC
    sub     rsp, 4*8+8 ; allocate shadow space

    ; Check if entities pool is created
    mov rax,bwPtr PTR entities_pool
    test rax, rax
    jnz pool_created

    lea rcx, entities_pool
    mov rdx,SIZEOF bwEntity
    mov r8,1024
    call bwPool_Create

pool_created:
    lea rcx, entities_pool
    call bwEntity_DrawAll
	
    add     rsp, 4*8+8 ; pop shadow space
	ret
bwWorld_Draw ENDP


endif