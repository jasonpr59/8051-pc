#ifndef MIT6115_JPR_INSTR_H_
#define MIT6115_JPR_INSTR_H_
;;; BEGIN PSEUDO-INSTRUCTIONS LIBRARY
load_from_dptr76:
;;; Load the value from @dptr76 into ACC.
	lcall swap_dptrs
	movx a, @dptr
	lcall swap_dptrs
	ret

store_to_dptr76:
;;; Store the value from ACC to @dptr76.
	lcall swap_dptrs
	movx @dptr, a
	lcall swap_dptrs
	ret

inc_dptr76:
;;; Increment DPTR76.
	xch a, r6
	add a, #1
	xch a, r6

	xch a, r7
	addc a, #0
	xch a, r7

	ret


swap_dptrs:
;;; Swap DPTR and DPTR76.  (Swaps the pointers themselves-- does not
;;; do any dereferencing.)
	xch a, r7
	xch a, dph
	xch a, r7

	xch a, r6
	xch a, dpl
	xch a, r6

	ret

;;; END PSEUDO-INSTRUCTIONS LIBRARY
#endif
