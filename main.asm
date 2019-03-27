;
; lab00-3.asm
;
; Created: 21/03/2019 2:20:17 PM
; Author : harry
;

;*****************ASSUMPTIONS*********************
;


; Replace with your application code
.include "m2560def.inc"
.equ floor_number = 3

.macro insertprog
		lpm r16, @0
		st y+, r16
.endmacro

.macro clear
	ldi YL, low(@0)
	ldi YH, high(@0)
	clr r20
	st Y+, r20
	st Y, r20
.endmacro

.def arraysize = r17
.def insert = r16
.def updwn = r18
.def curflor = r19

.dseg ; Set the starting address
	.org 0x200
vartab: 
	.byte 10
Flashing:
	.byte 1
FiveSecondCounter:
	.byte 1
TempCounter:
	.byte 2
FloorNumber:
	.byte 1
Direction:
	.byte 1

.cseg
.org 0x0000
	jmp RESET
	jmp DEFAULT
	jmp DEFAULT
	number: .db 4,9,3,10,9,6,2,8
	insertflo: .db 7,5,2,8

.org OVF0addr
	jmp OVF0address
	jmp DEFAULT
DEFAULT:
	reti
RESET:
	ldi r20, high(RAMEND)
	out SPH, r20
	ldi r20, low(RAMEND)
	out SPL, r20

	rjmp main
OVF0address: ;timer0 overflow
	in r20, SREG ;r20 is temp 
	push r20
	push YH
	push YL

	lds r24, TempCounter ;load tempcounter into r25:r24
	lds r25, TempCounter + 1
	adiw r25:r24, 1 ;increase tempcounter by 1
	cpi r24, low(2000) ;7812 * 2 
	ldi r20, high(2000) ;compare tempcounter with 2 seconds
	cpc r25, r20
		brlo NotSecond 

	lds r24, FloorNumber ;loading Floor number and direction into the stack 
	lds r25, Direction
	cp r24, r21 ;compare current floor with floor in the request
		breq FiveSecondPause
	std Y+1, r24
	std Y+2, r25

	clear TempCounter

	rcall updateFloor ;function to update the floor number and direction
	
	std Y+1, r24 ;store new floor number and direction in r24, r25
	std Y+2, r25
	ldd r24, Y+1
	ldd r25, Y+2
	sts FloorNumber, r24 ;pass r24 and r25 into floor number and direction in data memory
	sts Direction, r25
	rjmp endOVF0
NotSecond:
	sts TempCounter, r24
	sts TempCounter + 1, r25
	rjmp endOVF0
FiveSecondPause:
	lds r24, TempCounter ;load tempcounter into r25:r24
	lds r25, TempCounter + 1
	adiw r25:r24, 1 ;increase tempcounter by 1
	cpi r24, low(1000)
	ldi r20, high(1000)
	cpc r25, r20
		breq Flash
	cpi r24, low(7000) ;7812 * 2 + 7812 * 5
	ldi r20, high(7000) ;compare tempcounter with 7 seconds
	cpc r25, r20
		brlo NotSecond
	rjmp FiveSecondEnd
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv NOT YET FINISHED
Flash:
	lds r24, Flashing
	clr r20
	out PORTC, r20
	rjmp 
	;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
FiveSecondEnd:
	ld r21, X+
	clear TempCounter
	rjmp endOVF0
endOVF0:
	lds r24, FloorNumber
	lds r25, Direction
	std Y+1, r24
	std Y+2, r25

	rcall start1 ;function to load the floor number and direction onto the led bars

	pop YL
	pop YH
	pop r20
	out SREG, r20
	reti
updateFloor:
	push YL
	push YH
	in YL, SPL
	in YH, SPH
	sbiw Y, 2
	out SPL, YL
	out SPH, YH

	std Y+1, r24
	std Y+2, r25
	ldd r16, Y+1 ;Floor number
	ldd r17, Y+2 ;Direction
	cpi r17, 1 ;compare direction, 1 = going up, 0 = going down
		breq goingup
	rjmp goingdown
goingup:
	cpi r16, 10 ;has it reached floor 10 yet
		breq goingdown
	ldi r17, 1 ;set the direction to going up
	inc r16
	rjmp updateFloor_end
goingdown:
	cpi r16, 1 ;has it reached floor 1 yet
		breq goingup
	clr r17
	dec r16
	rjmp updateFloor_end
updateFloor_end:
	mov r24, r16
	mov r25, r17
	adiw Y, 2
	out SPH, YH
	out SPL, YL
	pop YH
	pop YL
	ret
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
	ldi updwn, 1 ;0 is down, 1 is up

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
	rjmp start  ;end of main function

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

start:

	ser r20
	out DDRC, r20 ;set Port C for output

	clear Flashing
	clear FiveSecondCounter
	clear TempCounter
	clear FloorNumber
	clear Direction
	clr r23
	ldi r20, 0b00000000 ;setting up the timer
	out TCCR0A, r20
	ldi r20, 0b00000010
	out TCCR0B, r20 ;set Prescaling value to 8
	ldi r20, 1<<TOIE0 ;128 microseconds
	sts TIMSK0, r20 ;T/C0 interrupt enable
	sei ;enable the global interrupt
	 ;SET STARTING FLOOR
	sts FloorNumber, curflor
	sts Direction, updwn
	ldi XH, high(vartab)
	ldi XL, low(vartab)
	ld r21, X+
	rjmp loop

start1:
	push YL
	push YH
	in YL, SPL
	in YH, SPH
	sbiw Y, 2
	out SPL, YL
	out SPH, YH

	std Y+1, r24
	std Y+2, r25
	ldd r16, Y+1 ;Floor number
	ldd r17, Y+2 ;Direction

	ldi r18, 1
	ldi r19, 1

	push r16
	clr r16
	out DDRG, r16
	pop r16

	cpi r16, 9
		breq floor9
		brge floor10
	rjmp leftshift
floor10:
	push r18
	ser r18
	out DDRG, r18
	ldi r18, 3
	out PORTG, r18
	pop r18
	rjmp leftshift
floor9:
	push r18
	ser r18
	out DDRG, r18
	ldi r18, 1
	out PORTG, r18
	pop r18
	rjmp leftshift
leftshift:
	cp r19, r16
		breq end
	lsl r18
	subi r18, -1
	inc r19
	rjmp leftshift
end:
	sts Flashing, r18
	out PORTC, r18
	adiw Y, 2
	out SPH, YH
	out SPL, YL
	pop YH
	pop YL
	ret
loop:
	rjmp loop

