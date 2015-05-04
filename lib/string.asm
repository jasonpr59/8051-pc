#ifndef MIT6115_JPR_STRING_H_
#define MIT6115_JPR_STRING_H_
;;; BEGIN STRING LIBRARY
string_equal:
;;; Checks if the string at dptr is equal to the string at dptr76,
;;; judging only by the first r0 characters.
	;; Save registers.  (ACC will contain the result, so we may
	;; clobber it.
	push dph
	push dpl
	mov a, r7
	push acc
	mov a, r6
	push acc

string_equal_loop:
	movx a, @dptr
	mov r1, a
	lcall load_from_dptr76
	clr C
	subb a, r1
	jnz string_equal_false

	;; Character pair was equal.  Prepare to compare next pair.
	inc dptr
	lcall inc_dptr76
	djnz r0, string_equal_loop

	;; All character pairs were equal!
	;; TODO(jasonpr): Factor out code duplicated between here
	;; and string_equal_false.
	pop acc
	mov r6, a
	pop acc
	mov r7, a
	pop dpl
	pop dph
	mov a, #TRUE
	ret

string_equal_false:
	pop acc
	mov r6, a
	pop acc
	mov r7, a
	pop dpl
	pop dph
	mov a, #FALSE
	ret


;;; END STRING LIBRARY
#endif

#include <boolean.asm>
