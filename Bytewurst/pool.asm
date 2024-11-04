bwPool STRUCT 16
	first bwPtr 0
	size_element QWORD 0
	count QWORD 0
	max_count QWORD 1024
bwPool ENDS

.code

; Insert a new element in the pool
; RCX pPool:Pool*
; Return: RAX pAddedElement:QWORD
bwPool_Add PROC
	sub rsp, 40

	xor rax,rax
	mov rdx,[rcx][bwPool.count]
	cmp rdx,[rcx][bwPool.max_count]
	jae L1

	; Calculate offset
	mov rax,[rcx][bwPool.count]
	mul [rcx][bwPool.size_element]

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

	mov [rcx][bwPool.size_element],rdx
	mov [rcx][bwPool.max_count],r8
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

	add rsp, 40
	ret
bwPool_Create ENDP
