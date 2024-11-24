.code
COMMENT @
; Insert a new element in the pool
; RCX pPool:Pool*
; Return: RAX pAddedElement:QWORD
bwPool_Add PROC
	sub rsp, 40

	xor rax,rax
	mov rdx,[rcx][bwPool.count]
	cmp rdx,[rcx][bwPool.capacity]
	jae L1	; Pool is full

	; Calculate offset
	mov rax,[rcx][bwPool.count]
	mul [rcx][bwPool.elementSize]

	; Add offset to first to get new element address
	add rax,bwPtr PTR [rcx]
	inc [rcx][bwPool.count]
L1:
	add rsp, 40
	ret
bwPool_Add ENDP

; RCX pPool:Pool*
; RDX size_element:QWORD
; R8 max_count:QWORD
bwPool_Create PROC
	sub rsp, 40

	mov [rcx][bwPool.elementSize],rdx
	mov [rcx][bwPool.capacity],r8
	mov [rcx][bwPool.count],0
	
	; Store pPool on stack
	mov [rsp+32],rcx

	; Allocate memory for the pool
	mov rax,rdx
	mul r8
	mov rcx,rax
	call malloc
	
	; Restore pPool
	mov rcx,[rsp+32]
	mov [rcx][bwPool.first],rax

	; Allocate memory for removed elements
	mov rax,rdx
	mov r9,SIZEOF QWORD
	mul r9
	mov rcx,rax
	call malloc
	; Restore pPool
	mov rcx,[rsp+32]
	mov [rcx][bwPool.recycledIndices],rax
	mov [rcx][bwPool.recycledCount],0


	add rsp, 40
	ret
bwPool_Create ENDP
 @