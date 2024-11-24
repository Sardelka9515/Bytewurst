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
bwEntity_Create PROC
	LOCAL bodyId:b2BodyId
	LOCAL sprite:sfPtr
	LOCAL pool:PTR bwEntity
	mov bodyId,rcx
	mov sprite,rdx
	mov pool,r8

	sub rsp, 40
	
	xor rax,rax
	mov rcx,[r8][bwPool.count]
	cmp rcx,[r8][bwPool.capacity]
	jae L1
	
	mov rcx,r8
	call bwPool_Add

	mov rcx,bodyId
	mov rdx,sprite
	mov b2BodyId PTR [rax],rcx
	mov sfPtr PTR [rax][bwEntity.pSprite],rdx
	mov float PTR [rax][bwEntity.health],0bf800000h ; -1.
	mov float PTR [rax][bwEntity.timeLeft],0bf800000h ; -1.
L1:
	add rsp, 40
	ret
bwEntity_Create ENDP

; RCX entity:bwEntity*
; RDX explode:BOOL
bwEntity_Kill PROC
	sub rsp,40
	mov float PTR [rcx][bwEntity.health],0
	mov float PTR [rcx][bwEntity.timeLeft],0
	test rdx,rdx
	jz L1

	; Explode entity


L1:
	; TODO Remove from entity pool
	; Overwrite this entity with entity at the end of the pool	
	; mov rsi,OFFSET entities
	; mov rax,entities_count
	; dec rax
	; mov entities_count,rax
	; imul rax,rax,SIZEOF bwEntity
	; add rsi,rax
	; 
	; mov rdi,rcx
	; mov rcx, SIZEOF bwEntity
	; rep movsb
	add rsp,40
	ret

bwEntity_Kill ENDP

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

pCurrentEntity$ = 32
pCounter$ = 24
numEntities$ = 16

; RCX entities:bwPool*
bwEntity_DrawAll PROC
	sub rsp,40

	mov rdx,[rcx][bwPool.count]
	mov pCounter$[rsp],rdx

	; Check if there are entities to draw
	test rdx,rdx
	jz L2

	mov rcx,bwPtr PTR [rcx]
	mov pCurrentEntity$[rsp],rcx
L1:
	mov rcx, QWORD PTR pCurrentEntity$[rsp]
	call bwEntity_Draw
	add  QWORD PTR pCurrentEntity$[rsp],SIZEOF bwEntity
	mov rdx,pCounter$[rsp]
	dec rdx
	mov pCounter$[rsp],rdx
	test rdx,rdx
	jnz L1

L2:
	add rsp,40
	ret

bwEntity_DrawAll ENDP
_TEXT ENDS


endif