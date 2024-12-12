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


entities_pool bwPool <0>

.code

; RCX halfSize:b2Vec2
; RDX pos:b2Vec2
; R8 bodyType:b2int
; Returns bodyId:b2BodyId
; Create a static or dynamic box
bwCreateBox PROC

    ALIGNED_LOCAL newBodyDef,b2BodyDef
    ALIGNED_LOCAL newBodyId,b2BodyId
    ALIGNED_LOCAL newShapeDef,b2ShapeDef
    ALIGNED_LOCAL halfSize,b2Vec2
    ALIGNED_LOCAL pos,b2Vec2
    ALIGNED_LOCAL bodyType,int32_t
    ALIGNED_LOCAL newBox,b2Polygon

    sub rsp, 4*8 ; allocate shadow space

    mov halfSize,rcx
    mov pos,rdx
    mov bodyType,r8d

    ; Create ground body def
    lea rcx, newBodyDef
    call b2DefaultBodyDef

    
    ; set body type
    mov eax, bodyType
    mov newBodyDef._type, eax

    ; set body position
    mov rax, pos
    mov newBodyDef.position, rax

    ; Create new body
    mov ecx, worldId
    lea rdx, newBodyDef
    call b2CreateBody
    mov newBodyId, rax

    ; Create new box
    lea rcx, newBox
    movss xmm1, REAL4 PTR halfSize.x
    mov rax,halfSize
    shr rax, 32
    movd xmm2, eax

    call b2MakeBox

    ; Create box shape
    lea rcx, newShapeDef
    call b2DefaultShapeDef
    mov newShapeDef.enableContactEvents, 1

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

    add rsp, 32 ; pop shadow space
    ret
bwCreateBox ENDP


; XMM0 radius:float
; RDX pos:b2Vec2
; R8 bodyType:b2int
; Returns bodyId:b2BodyId
; Create a static or dynamic ball
bwCreateBall PROC
    ALIGNED_LOCAL newBodyDef,b2BodyDef
    ALIGNED_LOCAL newBodyId,b2BodyId
    ALIGNED_LOCAL newShapeDef,b2ShapeDef
    ALIGNED_LOCAL radius,float
    ALIGNED_LOCAL pos,b2Vec2
    ALIGNED_LOCAL bodyType,int32_t
    ALIGNED_LOCAL newBall,b2Circle

    sub rsp, 4*8 ; allocate shadow space

    movss radius,XMM0
    mov pos,rdx
    mov bodyType,r8d

    
    ; Set circle params
    mov b2Vec2 PTR newBall.center,0
    movss float PTR newBall.radius,XMM0
    
    ; Create ground body def
    lea rcx, newBodyDef
    call b2DefaultBodyDef

    
    ; set body type
    mov eax, bodyType
    mov newBodyDef._type, eax

    ; set body position
    mov rax, pos
    mov newBodyDef.position, rax

    ; Create new body
    mov ecx, worldId
    lea rdx, newBodyDef
    call b2CreateBody
    mov newBodyId, rax

    ; Create shape
    lea rcx, newShapeDef
    call b2DefaultShapeDef
    mov newShapeDef.enableContactEvents, 1

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

    add rsp, 32 ; pop shadow space
    ret
bwCreateBall ENDP

; RCX pos:b2Vec2
; XMM1 radius:float
bwCreateExplosion PROC
    ALIGNED_LOCAL pos,b2Vec2
    ALIGNED_LOCAL def,b2ExplosionDef
    sub rsp, 4*8 ; allocate shadow space

    mov def.position, rcx
    movd def.radius,xmm1
    mov def.impulsePerLength, 42480000h ;50.0
    mov def.falloff,40a00000h  ;5.0
    mov def.maskBits,0ffffffffffffffffh

    mov ecx,worldId
    lea rdx, def
    call b2World_Explode

    add rsp, 32 ; pop shadow space
    ret
bwCreateExplosion ENDP

bwWorld_Draw PROC
    sub     rsp, 4*8+8 ; allocate shadow space

    
	; Set to current world view
    mov rcx,window
	mov rdx, pView
	call sfRenderWindow_setView

	; set window as draw context
	mov rax,window
	mov debug_draw.context, rax

	; set worldId to rcx and draw debug
	mov ecx,worldId
	lea rdx, debug_draw
	call b2World_Draw


    ; Check if entities pool is created
    mov rax,bwPtr PTR entities_pool
    test rax, rax
    jnz pool_created

    lea rcx, entities_pool
    mov rdx,SIZEOF bwEntity
    mov r8,1024
    call bwPool_Init

pool_created:

    add     rsp, 4*8+8 ; pop shadow space
	ret
bwWorld_Draw ENDP


endif