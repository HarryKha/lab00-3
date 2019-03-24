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

.macro clear
	ldi YL, low(@0)
	ldi YH, high(@0)
	clr r20
	st Y+, r20
	st Y, r20
.endmacro

.dseg ; Set the starting address
	.org 0x200
SecondCounter:
	.byte 2
TempCounter:
	.byte 2
FloorNumber:
	.byte 1
Direction:
	.byte 1

.cseg
.org 0x0000
	jmp RESET
.org OVF0addr
	jmp OVF0address
	rjmp start1
RESET:
	ldi r20, high(RAMEND)
	out SPH, r20
	ldi r20, low(RAMEND)
	out SPL, r20

	ser r16
	out DDRC, r16 ;set Port C for output
;	out DDRG, r16 ;set Port G for output

	clear SecondCounter
	clear TempCounter
	ldi r20, 0b00000000 ;setting up the timer
	out TCCR0A, r20
	ldi r20, 0b00000010
	out TCCR0B, r20 ;set Prescaling value to 8
	ldi r20, 1<<TOIE0 ;128 microseconds
	sts TIMSK0, r20 ;T/C0 interrupt enable
	sei ;enable the global interrupt

	rjmp start
OVF0address: ;timer0 overflow
	in r20, SREG ;r20 is temp 
	push r20
	push YH
	push YL
	;push r24
	;push r25

	lds r24, TempCounter ;load tempcounter into r25:r24
	lds r25, TempCounter + 1
	adiw r25:r24, 1 ;increase tempcounter by 1
	cpi r24, low(3000) ;7812 * 2 
	ldi r20, high(3000) ;compare tempcounter with 2 seconds
	cpc r25, r20
	brne NotSecond 
	clear TempCounter

	ldi YL, low(RAMEND - 2) ;prepare stack pointer for function call
	ldi YH, high(RAMEND - 2) ;this function just updates the floor number and direction every 2 seconds
	out SPL, YL
	out SPH, YH

	lds r24, FloorNumber
	lds r25, Direction
	std Y+1, r24
	std Y+2, r25

	rcall updateFloor
	
	std Y+1, r24 ;store new floor number and direction in r24, r25
	std Y+2, r25
	sts FloorNumber, r24 ;pass r24 and r25 into floor number and direction in data memory
	sts Direction, r25
	rjmp endOVF0
NotSecond:
	sts TempCounter, r24
	sts TempCounter + 1, r25
	rjmp endOVF0
Second:
	lds r24, SecondCounter
	lds r25, SecondCounter + 1
	adiw r25:r24, 1
	sts SecondCounter, r24
	sts SecondCounter + 1, r25
endOVF0:
	ldi YL, low(RAMEND - 2)
	ldi YH, high(RAMEND - 2)
	out SPL, YL
	out SPH, YH

	lds r24, FloorNumber
	lds r25, Direction
	std Y+1, r24
	std Y+2, r25

	rcall start1

	;std Y+1, r24
	;std Y+2, r25
	;lds r24, FloorNumber
	;lds r25, Direction

	;pop r25
	;pop r24
	pop YL
	pop YH
	pop r20
	out SREG, r20
	reti
updateFloor:
	push YL
	push YH
	push r16
	push r17
	in YL, SPL
	in YH, SPH
	sbiw Y, 2
	out SPL, YL
	out SPH, YH

	std Y+1, r24
	std Y+2, r25
	ldd r16, Y+1 ;Floor number
	ldd r17, Y+2 ;Direction
	cpi r17, 1 ;compare direction
		breq goingup
	rjmp goingdown
goingup:
	cpi r16, 10
		breq goingdown
	ldi r17, 1 ;set the direction to going up
	inc r16
	rjmp updateFloor_end
goingdown:
	cpi r16, 1
		breq goingup
	ldi r17, 0
	dec r16
updateFloor_end:
	mov r24, r16
	mov r25, r17
	adiw Y, 2
	out SPH, YH
	out SPL, YL
	pop r17
	pop r16
	pop YH
	pop YL
	ret
start:
	lds r18, FloorNumber
	ldi r18, 1
	sts FloorNumber, r18
	lds r19, Direction
	ldi r19, 1
	sts Direction, r19
	rjmp loop
start1:
	push YL
	push YH
	push r16
	push r17
	in YL, SPL
	in YH, SPH
	sbiw Y, 2
	out SPL, YL
	out SPH, YH

	std Y+1, r24
	std Y+2, r25
	ldd r16, Y+1 ;Floor number
	ldd r17, Y+2 ;Direction

	ldi r17, 1
	ldi r16, 1
	lds r18, FloorNumber
	lds r19, Direction

	push r16
	clr r16
	out DDRG, r16
	pop r16

	cpi r18, 9
		breq floor9
		brge floor10
	cpi r18, 1
		breq floor1
	rjmp leftshift
floor10:
	push r18
	ser r18
	out DDRG, r18
	ldi r18, 3
	out PORTG, r18
	pop r18
	ldi r19, 0 ;start going down
	rjmp leftshift
floor9:
	push r18
	ser r18
	out DDRG, r18
	ldi r18, 1
	out PORTG, r18
	pop r18
	rjmp leftshift
floor1:
	ldi r19, 1 ;start going up
leftshift:
	cp r17, r18
		breq end
	lsl r16
	subi r16, -1
	inc r17
	rjmp leftshift
end:
	out PORTC, r16
	mov r24, r16
	mov r25, r17
	adiw Y, 2
	out SPH, YH
	out SPL, YL
	pop r25
	pop r24
	pop YH
	pop YL
	ret
loop:
	rjmp loop

