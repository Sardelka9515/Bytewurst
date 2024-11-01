.code
ifndef __ENTITY_INC__
__ENTITY_INC__:

INCLUDE draw.asm


bwEntity STRUCT 16
	bodyId b2BodyId <>
	pSprite sfPtr 0
	health float -1.
	lifeSpan float -1.
bwEntity ENDS

.data
MAX_ENTITIES = 1024
entities bwEntity MAX_ENTITIES dup(<>)
entities_count QWORD 0

.code

; RCX bodyId:b2BodyId
; RDX pSprite:sfPtr
; Return RAX:bwEntity*
bwEntity_Create PROC
	sub rsp, 40
	xor rax,rax
	cmp entities_count,MAX_ENTITIES
	jae L1
	lea rax,entities
	imul r8,entities_count,SIZEOF bwEntity
	add rax,r8
	mov b2BodyId PTR [rax],rcx
	mov sfPtr PTR [rax][bwEntity.pSprite],rdx
	mov float PTR [rax][bwEntity.health],0bf800000h ; -1.
	mov float PTR [rax][bwEntity.lifeSpan],0bf800000h ; -1.
	inc entities_count
L1:
	add rsp, 40
	ret
bwEntity_Create ENDP

; RCX entity:bwEntity*
; RDX explode:BOOL
bwEntity_Kill PROC
	sub rsp,40
	mov float PTR [rcx][bwEntity.health],0
	mov float PTR [rcx][bwEntity.lifeSpan],0
	test rdx,rdx
	jz L1

	; Explode entity


L1:
	; Remove from entity pool
	; Overwrite this entity with entity at the end of the pool	
	mov rsi,OFFSET entities
	mov rax,entities_count
	dec rax
	mov entities_count,rax
	imul rax,rax,SIZEOF bwEntity
	add rsi,rax

	mov rdi,rcx
	mov rcx, SIZEOF bwEntity
	rep movsb
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
bwEntity_DrawAll PROC
	sub rsp,40

	mov rdx,entities_count
	mov pCounter$[rsp],rdx

	; Check if there are entities to draw
	test rdx,rdx
	jz L2

	mov rcx,OFFSET entities
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