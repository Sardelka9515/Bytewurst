.code
ifndef __DRAW_INC__
__DRAW_INC__:

INCLUDE csfml.inc

.data
degToRadian REAL4 57.2957795131 
renderStates sfRenderStates <>
view_center sfVector2f <0.,15.>
view_size sfVector2f <64.,36.>
color sfColor <0, 0, 255, 0>
debug_draw b2DebugDraw <>
timer b2Timer <0>
font_path BYTE "C:\\Windows\\fonts\\arial.ttf"
view_size_y_flip QWORD 8000000000000000h

pView QWORD 0
pPolygon QWORD 0
pCircle QWORD 0
pFont QWORD 0
pFpsText QWORD 0

; Textures
img_path BYTE "img\\sausage.png"
pTexture QWORD 0
pSprite QWORD 0

spriteScale sfVector2f <0.002, -0.002>
spriteOrigin sfVector2f <1024., 1024.>

.code

; Convert a b2HexColor to sfColor and store it in eax, r8d will be overwritten as temp storage
; ECX hex:b2HexColor
HexToRGBA PROC
	
	sub rsp, 40
	
	; Set alpha to 255
	mov eax, 0ff000000h

	; R
	mov r8d, ecx
	and r8d, 0ff0000h
	shr r8d, 16
	or eax, r8d

	; G
	mov r8d, ecx
	and r8d, 00ff00h
	or eax, r8d

	; B
	mov r8d, ecx
	and r8d, 0000ffh
	shl r8d, 16
	or eax, r8d
	
	add rsp, 40
	ret
HexToRGBA ENDP

; RCX center:sfVector2f
; RDX size:sfVector2f
bwUpdateView PROC
	ALIGNED_LOCAL center,sfVector2f
	; store center on stack
	mov center,rcx
	sub rsp, 40

	; flip sign bit of size.y (upper 32 bits of rdx)
	xor rdx, view_size_y_flip

	; set size
	mov rcx, pView
	call sfView_setSize

	; Restore center to rdx and set view center
	mov rcx, pView
	mov rdx,center
	call sfView_setCenter

	add rsp, 40
	ret
bwUpdateView ENDP

bwSetup PROC
	sub rsp, 40 ; shadow space

	; Create timer
	call b2CreateTimer
	mov timer, rax

	; Set up debug draw
	lea rcx, debug_draw
	call b2DefaultDebugDraw

	; Set up font
	lea rcx, font_path
	call sfFont_createFromFile
	mov pFont, rax

	; Set up fps text
	call sfText_create
	mov pFpsText, rax

	mov rcx, pFpsText
	mov rdx, pFont
	call sfText_setFont
	
	mov rcx, pFpsText
	lea rdx, window_title
	call sfText_setString
	
	mov rcx, pFpsText
	mov rdx, 24
	call sfText_setCharacterSize

	mov rcx, pFpsText
	mov rdx, 0ff000000h  ; white
	call sfText_setFillColor

	; Create draw polygon
	call sfConvexShape_create
	mov pPolygon, rax

	; Create draw circle
	call sfCircleShape_create
	mov pCircle, rax

	; Create view
	call sfView_create
	mov pView, rax

	; Create default RenderStates
	lea rcx, renderStates
	mov rax, SIZEOF renderStates
	call sfRenderStates_default
	
	; Set default view
	mov rcx, view_center
	mov rdx, view_size
	call bwUpdateView

	; Set up drawing functions
	mov debug_draw.drawShapes, true

	lea rax, bwDrawSolidPolygon
	mov debug_draw.DrawSolidPolygon, rax
	lea rax, bwDrawSolidCircle
	mov debug_draw.DrawSolidCircle, rax

	; Load textures
	lea rcx, img_path
	xor rdx, rdx
	call bwLoadSprite
	mov pSprite, rax
	
	; Set sprite scale
	mov rcx, pSprite
	mov rdx, spriteScale
	call sfSprite_setScale

	; Set sprite origin
	mov rcx, pSprite
	mov rdx, spriteOrigin
	call sfSprite_setOrigin


	add rsp, 40 ; shadow space
	ret
bwSetup ENDP

_TEXT SEGMENT

context$		= 40+48		; QWORD
color$			= context$ - SIZEOF QWORD	; Although b2HexColor is only 4 bytes, arguments pushed to stack takes 8 bytes each
radius$			= color$ - SIZEOF REAL4
vertexCount$	= radius$ - SIZEOF DWORD
vertices$		= vertexCount$ - SIZEOF QWORD
pTransform$		= vertices$	- SIZEOF QWORD

bwDrawSolidPolygon PROC
	sub rsp, 40

	mov pTransform$[rsp],rcx

	mov vertices$[rsp],rdx

	mov vertexCount$[rsp],r8d
	
	movss REAL4 PTR radius$[rsp],xmm3

	mov rcx, pPolygon
	mov edx, r8d
	call sfConvexShape_setPointCount

	mov ecx, DWORD PTR vertexCount$[rsp]


set_points:
	
	; store loop counter on stack
	mov  DWORD PTR vertexCount$[rsp],ecx
	
	; Use rdx to index vertices
	mov rdx, rcx

	; Store pointer to vertex in rax
	dec rdx
	imul r9, rdx, SIZEOF b2Vec2

	; load vertex to r8
	mov rax, vertices$[rsp]
	add rax, r9
	mov r8, b2Vec2 PTR [rax]
	
	; Set vertex
	mov rcx, pPolygon
	call sfConvexShape_setPoint

	; Restore loop counter to rcx
	mov ecx, DWORD PTR vertexCount$[rsp]

	loop set_points


	; Set polygon position
	mov rcx, pPolygon
	mov rax, pTransform$[rsp]
	mov rdx, QWORD PTR [rax][b2Transform.p.x]
	call sfConvexShape_setPosition

	; Calculate rotation angle in degrees
	mov rax, pTransform$[rsp]
	movss xmm0, DWORD PTR [rax][b2Transform.q.s]
	movss xmm1, DWORD PTR [rax][b2Transform.q.c]
	call b2Atan2
	mulss xmm0, degToRadian
	movss xmm1, xmm0


	; Set polygon rotation
	mov rcx, pPolygon
	call sfConvexShape_setRotation

	; Set fill color
	mov ecx, DWORD PTR color$[rsp]
	call HexToRGBA 

	mov rcx, pPolygon
	mov rdx, rax
	call sfConvexShape_setFillColor

	mov rcx, QWORD PTR context$[rsp]
	mov rdx, pPolygon
	lea r8, renderStates
	call sfRenderWindow_drawConvexShape
	nop
	add rsp, 40
	ret
bwDrawSolidPolygon ENDP
_TEXT ENDS


_TEXT SEGMENT
context$		= 40+32		; QWORD
color$			= context$ - SIZEOF QWORD
radius$			= color$ - SIZEOF REAL4
pTransform$		= radius$	- SIZEOF QWORD


.data
vec_test b2Vec2 <>

.code
; RCX transform:b2Transform*
; XMM1 radius:float
; R8 color:b2HexColor
; R9 context:sfRenderWindow*
bwDrawSolidCircle PROC
	sub rsp,40

	mov pTransform$[rsp],rcx
	movss float PTR radius$[rsp],xmm1
	mov color$[rsp],r8
	mov context$[rsp],r9

	mov rcx, pCircle
	call sfCircleShape_setRadius


	; Set position
	mov rcx, pCircle
	mov rax, pTransform$[rsp]

	; will need to add radius as offset to draw
	mov rdx, QWORD PTR [rax][b2Transform.p.x]
	movlps xmm0, QWORD PTR [rax][b2Transform.p.x]
	
	mov eax,float PTR radius$[rsp]
	mov edx,eax
	shl rax,32
	or rax,rdx
	push rax
	movlps xmm1,QWORD PTR [rsp]
	pop rax

	subps xmm0,xmm1

	movq rdx, xmm0
	mov vec_test,rdx
	call sfCircleShape_setPosition

	mov rcx, pCircle
	mov rdx, 64
	call sfCircleShape_setPointCount

	mov rcx,color$[rsp]
	call HexToRGBA
	mov rcx,pCircle
	mov edx,eax
	call sfCircleShape_setFillColor

	mov rcx,context$[rsp]
	mov rdx,pCircle
	lea r8,renderStates
	call sfRenderWindow_drawCircleShape

	add rsp,40
	ret
bwDrawSolidCircle ENDP
_TEXT ENDS

endif