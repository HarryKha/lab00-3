.include "m2560def.inc"
	.dseg
	vartab: .byte 10
	.cseg
	number: .db 5,3,2,10,11,15,0,0
	insertflo: .db 13,4,17,8
	.macro insertprog
		lpm r16, @0
		st y+, r16
	.endmacro

.def arraysize = r17
.def insert = r16
.def updwn = r18
.def curflor = r19

main:
	ldi zl, low(number<<1)
	ldi zh, high(number<<1)
	ldi yl, low(vartab)
	ldi yh, high(vartab)
	;insert array into data memory
	insertprog z+
	insertprog z+
	insertprog z+
	insertprog z+
	insertprog z+
	insertprog z+
	insertprog z+
	insertprog z+
	ldi arraysize, 6
	ldi curflor, 8
	ldi updwn, 0 ;0 is down, 1 is up

	ldi zl,low(insertflo<<1)
	ldi zh,high(insertflo<<1)
	ldi yl, low(RAMEND-4) ;4bytes to store local variables
	ldi yh, high(RAMEND-4) ;assume variable is 1 byte
	out SPH, yh ;adjust stack pointer to poin to new stack top
	out SPL, yl
	;*******************************************************************
	lpm insert, z+ ; floor to be inserted = 13
	std y+1, insert ;store initial parameters
	std y+2, arraysize
	std y+3, curflor
	std y+4, updwn

	;prepare parameters for function call
	ldd r21, y+1 ; r21 holds the insert number parameter
	ldd r22, y+2 ; r22 holds arraysize parameter
	ldd r23, y+3 ; r23 holds current floor parameter
	ldd r24, y+4 ; r24 holds lift direction parameter

	rcall insert_request ; call subroutine
	mov arraysize, r21 ;move returned number back to r17
	;*******************************************************************
	lpm insert, z+ ; floor to be inserted = 4
	std y+1, insert ;store initial parameters
	std y+2, arraysize
	std y+3, curflor
	std y+4, updwn

	;prepare parameters for function call
	ldd r21, y+1 ; r21 holds the insert number parameter
	ldd r22, y+2 ; r22 holds arraysize parameter
	ldd r23, y+3 ; r23 holds current floor parameter
	ldd r24, y+4 ; r24 holds lift direction parameter

	rcall insert_request ; call subroutine
	mov arraysize, r21 ;move returned number back to r17
	;*******************************************************************
	lpm insert, z+ ; floor to be inserted = 17
	std y+1, insert ;store initial parameters
	std y+2, arraysize
	std y+3, curflor
	std y+4, updwn

	;prepare parameters for function call
	ldd r21, y+1 ; r21 holds the insert number parameter
	ldd r22, y+2 ; r22 holds arraysize parameter
	ldd r23, y+3 ; r23 holds current floor parameter
	ldd r24, y+4 ; r24 holds lift direction parameter

	rcall insert_request ; call subroutine
	mov arraysize, r21 ;move returned number back to r17
	;*******************************************************************
	
	lpm insert, z+ ; floor to be inserted = 8
	std y+1, insert ;store initial parameters
	std y+2, arraysize
	std y+3, curflor
	std y+4, updwn

	;prepare parameters for function call
	ldd r21, y+1 ; r21 holds the insert number parameter
	ldd r22, y+2 ; r22 holds arraysize parameter
	ldd r23, y+3 ; r23 holds current floor parameter
	ldd r24, y+4 ; r24 holds lift direction parameter

	rcall insert_request ; call subroutine
	mov arraysize, r21 ;move returned number back to r17
	;*******************************************************************
end:
	rjmp end ;end of main function

insert_request:
	;prologue
	push yl ;save y in stack
	push yh
	push zl
	push zh
	push r15
	push r16 ;save registers used in function
	push r17
	push r18
	push r19
	push r20
	
	in yl, SPL ;initialize the stack frame pointer value
	in yh, SPH
	sbiw y, 8	;reserve space for local variables and parameters
	out SPH, yh ;update stack pointer to top
	out SPL, yl
	;pass parameters
	std y+1, r21 ;pass insert number to stack
	std y+2, r22 ;pass array size to stack
	std y+3, r23 ;pass current flor to stack
	std y+4, r24 ;pass lift movement to stack
	
	;function body
	ldd r20, y+2 ;load arraysize
	ldd r19, y+1 ;load inserted number
	ldd r16, y+3 ;load current floor
	ldd r18, y+4 ;load lift movement

	;insert number into data mem in order
	clr r15 ;used for array counter
	ldi zl, low(vartab)
	ldi zh, high(vartab)

	cp r16, r19 ;compare current floor to insert floor
	breq exist ;inserted floor is the current floor
	brlo greater ;inserted floor is greater than current floor
	jmp lower ;inserted floor is lower than current floor

	lower:
	cpi r18, 0 ;check lift movement
	breq dwn
	ldi r16, 255
	dwn:
	ld r17, z+ ;load current array element
	cp r19, r17 ;compare the insert number to current array element
	breq exist ;number exists in array, therefore do no insert
	brsh smaller ;array element is smaller than insert number
	cp r17, r16 ;compare current floor to array element (if moving up r16 = 255)
	brsh smaller ;reached increasing part of array (ie.r17<r16)
	cp r15, r20 ;compare current array count to array size
	breq endarray ;if equal, at end of array
	inc r15 ;increment array counter
	jmp dwn ;array element smaller than insert number

	greater:
	cpi r18, 1 ;check lift movement
	breq up
	ldi r16, 0
	up:
	ld r17, z+ ;load current array element
	cp r19, r17 ;compare the insert number to current array element
	breq exist ;number exists in array, therefore do no insert
	brlo smaller ;array element is larger than insert number
	cp r17, r16 ;compare current floor to array element (if moving down r16 = 0)
	brlo smaller ;reached decreasing part of array (ie.r17<r16)
	cp r15, r20 ;compare current array count to array size
	breq endarray ;if equal, at end of array
	inc r15 ;increment array counter
	jmp up ;array element smaller than insert number
	
	smaller:
	st -z, r19 ;store array element
	ld r15, z+ ;increment z
	
	movedwn: ;move each element down the array
	ld r18, z
	cp r17, r18
	breq fin ;r17 = r18 because no repeating element therefore
	st z+, r17 ;r17 and r18 must contain 0 (buffer 0)
	ld r17, z
	cp r17, r18
	st z+, r18
	breq endmov
	jmp movedwn
	
	endmov:
	st z+, r17
	jmp fin
	
	endarray:
	st -z, r19
	
	fin:
	inc r20
	
	exist:
	mov r21, r20 ;move arraysize to r21
	adiw y, 8 ;de allocate the reserved space
	out SPH, yh
	out SPL, yl
	pop r20
	pop r19 ;restore registers
	pop r18
	pop r17
	pop r16
	pop r15
	pop zh
	pop zl
	pop yh
	pop yl
	ret