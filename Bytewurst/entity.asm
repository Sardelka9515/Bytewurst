.code
ifndef __ENTITY_INC__
__ENTITY_INC__:

INCLUDE draw.asm

.data

.code

; RCX bodyId:b2BodyId
; RDX pSprite:sfPtr
; R8 pool:bwPool*
; Return RAX:bwEntity*
_bwEntity_Create PROC
	ALIGNED_LOCAL bodyId,b2BodyId
	ALIGNED_LOCAL sprite,sfPtr
	ALIGNED_LOCAL pool,bwPtr
	ALIGNED_LOCAL index,size_t
	mov bodyId,rcx
	mov sprite,rdx
	mov pool,r8

	sub rsp, 32
	
	xor rax,rax
	mov rcx,[r8][bwPool._size]
	cmp rcx,[r8][bwPool.capacity]
	jae L1
	
	mov rcx,r8
	call bwPool_Add
	mov index,rax

	mov rcx,pool
	mov rdx,rax
	call bwPool_Get

	mov rcx,bodyId
	mov rdx,sprite
	mov b2BodyId PTR [rax],rcx
	mov sfPtr PTR [rax][bwEntity.pSprite],rdx
	mov float PTR [rax][bwEntity.health],0bf800000h ; -1.
	mov float PTR [rax][bwEntity.timeLeft],040a00000h ; 5.
	mov float PTR [rax][bwEntity.explosionStrength],040a00000h ; 5.
	mov uint32_t PTR [rax][bwEntity.explosionParts],20
	mov rdx,index
	mov size_t PTR [rax][bwEntity.index],rdx
	mov rdx,pool
	mov bwPtr PTR [rax][bwEntity.pPool],rdx
L1:
	add rsp, 32
	ret
_bwEntity_Create ENDP

_TEXT SEGMENT
bodyId$ = 32
pSprite$ = 24

; RCX entity:bwEntity*
bwEntity_Draw PROC
	sub rsp,40

	; Save entity to stack
	mov rax, b2BodyId PTR [rcx]
	mov b2BodyId PTR bodyId$[rsp],rax

	mov rax, sfPtr PTR [rcx][bwEntity.pSprite]
	mov sfPtr PTR pSprite$[rsp],rax

	; Get position from b2Body
	mov rcx, b2BodyId PTR [rcx]
	call b2Body_GetPosition
	
	; Set position to sfSprite
	mov rdx, rax
	mov rcx, sfPtr PTR pSprite$[rsp]
	call sfSprite_setPosition

	; Get rotation from b2Body
	mov rcx, b2BodyId PTR bodyId$[rsp]
	call b2Body_GetRotation
	
	; Calculate rotation in degrees
	movd xmm1, eax
	shr rax, 32
	movd xmm0, eax
	call b2Atan2

	mov rcx,pSprite$[rsp]
	movss xmm1,xmm0
	mulss xmm1, degToRadian
	call sfSprite_setRotation

	; Draw sprite
	mov rcx, window
	mov rdx, sfPtr PTR pSprite$[rsp]
	lea r8, renderStates
	call sfRenderWindow_drawSprite
	add rsp,40
	ret

bwEntity_Draw ENDP
_TEXT ENDS

_TEXT SEGMENT

; RCX entities:bwPool*
bwEntity_DrawAll PROC
	ALIGNED_LOCAL pCurrentEntity,bwPtr
	ALIGNED_LOCAL pCounter,QWORD
	ALIGNED_LOCAL numEntities,QWORD
	sub rsp,32

	mov rdx,[rcx][bwPool._size]
	mov pCounter,rdx

	; Check if there are entities to draw
	test rdx,rdx
	jz no_entities

	mov rcx,bwPtr PTR [rcx]
	mov pCurrentEntity,rcx
L1:
	mov rcx, QWORD PTR pCurrentEntity
	movd xmm1,timeStep
	mov r8,window
	lea r9,renderStates
	call bwEntity_Update

	add  QWORD PTR pCurrentEntity,SIZEOF bwEntity
	mov rdx,pCounter
	dec rdx
	mov pCounter,rdx
	test rdx,rdx
	jnz L1

no_entities:
	add rsp,32
	ret

bwEntity_DrawAll ENDP
_TEXT ENDS


endif