#ifndef MIT6115_JPR_MATH_H_
#define MIT6115_JPR_MATH_H_
;;; BEGIN MATH LIBRARY
sum_32bit:
;;; Does r[3:0] = r[3:0] + r[7:4], with MSB in high reg.
	clr C

	xch a, r0
	addc a, r4
	xch a, r0

	xch a, r1
	addc a, r5
	xch a, r1

	xch a, r2
	addc a, r6
	xch a, r2

	xch a, r3
	addc a, r6
	xch a, r3

	ret

mul_32by8bit:
;;; Does r[4:0] = r[3:0] * r4
	push b
	push acc
	push 5			; R5.

	;; Clear the carry byte.
	mov r5, #0

	;; R0
	mov b, r4
	mov a, r0
	mul ab
	add a, r5
	mov r0, a
	mov r5, b
	;; R1
	mov b, r4
	mov a, r1
	mul ab
	add a, r5
	mov r1, a
	mov r5, b
	;; R2
	mov b, r4
	mov a, r2
	mul ab
	add a, r5
	mov r2, a
	mov r5, b
	;; R3
	mov b, r4
	mov a, r3
	mul ab
	add a, r5
	mov r3, a
	mov r5, b

	;; Carry ends in r4.
	mov a, r5
	mov r4, a

	pop 5 			; R5
	pop acc
	pop b
	ret

load_32bit_low:
;;; Loads four bytes at data pointer into r[3:0].
	push dph
	push dpl
	push acc

	movx a, @dptr
	mov r0, a
	inc dptr

	movx a, @dptr
	mov r1, a
	inc dptr

	movx a, @dptr
	mov r2, a
	inc dptr

	movx a, @dptr
	mov r3, a

	pop acc
	pop dpl
	pop dph
	ret

load_32bit_high:
;;; Loads four bytes at data pointer int r[7:4].
	push dph
	push dpl
	push acc

	movx a, @dptr
	mov r4, a
	inc dptr

	movx a, @dptr
	mov r5, a
	inc dptr

	movx a, @dptr
	mov r6, a
	inc dptr

	movx a, @dptr
	mov r7, a

	pop acc
	pop dpl
	pop dph
	ret

store_32bit_low:
;;; Stores four bytes in r[3:0] to @dptr.
	push dph
	push dpl
	push acc

	mov a, r0
	movx @dptr, a
	inc dptr

	mov a, r1
	movx @dptr, a
	inc dptr

	mov a, r2
	movx @dptr, a
	inc dptr

	mov a, r3
	movx @dptr, a

	pop acc
	pop dpl
	pop dph
	ret

store_32bit_high:
;;; Stores four bytes in r[7:4] to @dptr.
	push dph
	push dpl
	push acc

	mov a, r4
	movx @dptr, a
	inc dptr

	mov a, r5
	movx @dptr, a
	inc dptr

	mov a, r6
	movx @dptr, a
	inc dptr

	mov a, r7
	movx @dptr, a

	pop acc
	pop dpl
	pop dph
	ret

endian_swap:
;;; Moves r[3:0] to r[0:3].
	xch a, r0
	xch a, r3
	xch a, r0

	xch a, r1
	xch a, r2
	xch a, r1

	ret

;;; END MATH LIBRARY
#endif
