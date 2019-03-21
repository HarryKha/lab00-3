;
; lab00-3.asm
;
; Created: 21/03/2019 2:20:17 PM
; Author : harry
;


; Replace with your application code
.include "m2560def.inc"
.equ floor_number = 5
	.dseg ; Set the starting address
	.org 0x200
	.cseg
	rjmp start 
start: 
	ser r16
	out DDRC, r16 ;set Port C for output
	ldi r17, 1
	ldi r16, 1
leftshift:
	cpi r17, floor_number
		breq end
	lsl r16
	subi r16, -1
	inc r17
	rjmp leftshift
end:
	out PORTC, r16
loop:
	rjmp loop