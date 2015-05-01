#ifndef MIT6115_JPR_CRC_H_
#define MIT6115_JPR_CRC_H_
;;; BEGIN CRC LIBRARY
;;; All CRCs in this library are the 7-bit SD card crc,
;;; x^7 + x^3 + 1.

crc_fold_bit:
;;; Given a CRC in ACC[7:1] and a next bit in C, fold the bit into the
;;; CRC.
	jnc crc_post_intro_xor
	add a, #0x80
crc_post_intro_xor:
	clr C
	rlc a
	jnc crc_post_update_xor
	xrl a, #0b00010010
crc_post_update_xor:
	ret

crc_fold_byte:
;;; Given a CRC in ACC[7:1] and a byte in B, fold the byte into the
;;; CRC.
	;; TODO(jasonpr): Turn this into a loop on a bit address.
	clr C
	orl C, B.7
	lcall crc_fold_bit
	clr C
	orl C, B.6
	lcall crc_fold_bit
	clr C
	orl C, B.5
	lcall crc_fold_bit
	clr C
	orl C, B.4
	lcall crc_fold_bit
	clr C
	orl C, B.3
	lcall crc_fold_bit
	clr C
	orl C, B.2
	lcall crc_fold_bit
	clr C
	orl C, B.1
	lcall crc_fold_bit
	clr C
	orl C, B.0
	lcall crc_fold_bit
	ret

;;; END CRC LIBRARY
#endif
