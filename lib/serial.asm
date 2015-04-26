#ifndef MIT6115_JPR_SERIAL_H_
#define MIT6115_JPR_SERIAL_H_
;;; BEGIN SERIAL LIBRARY
serial_init:
;;; Prepare for 9600-baud serial communication.
	mov TMOD, #0x20		; Put Timer 1 in Mode 2 (auto-relad)
	setb TR1		; Run Timer 1.
	setb IT0		; Put interrupt 0 in falling-edge mode.
				; TODO(jasonpr): Is this necessary?
	mov TH1, #0xFD		; Setup 9600 baud.
	mov SCON, #0x50		; Enable UART in 8-bit mode.
	ret

serial_read:
;;; Poll until we receive a serial character.
;;; Return it in ACC.
	jnb RI, serial_read
	mov a, SBUF
	clr ri
	ret

serial_write:
;;; Send the character in ACC over the serial port.
;;; Only return once the character is sent.
	clr TI
	mov SBUF, a
serial_write_loop:
	jnb TI, serial_write_loop
	ret


serial_print:
;;; Print the null-terminated string to which DPTR points.
;;; Clobbers: ACC, DPTR.
	movx a, @dptr
	inc dptr
	jz serial_print_done
	lcall serial_write
	sjmp serial_print
serial_print_done:
	ret

serial_write_space:
;;; Writes a space to the serial port.
	push ACC
	mov a, #0x20
	lcall serial_write
	pop ACC
	ret

serial_write_crlf:
;;; Writes a CRLF to the serial port.
	push ACC

	mov a, #0x0D 		; CR
	lcall serial_write

	mov a, #0x0A 		; LF
	lcall serial_write

	pop ACC
	ret

serial_read_ascii_byte:
;;; Read two hexidecimal ascii characters, convert them to a byte.
	lcall serial_read
	lcall ascii_to_nibble
	swap a
	push ACC

	lcall serial_read
	lcall ascii_to_nibble

	mov b, a
	pop ACC
	add a, b

	ret
ascii_to_nibble:
;;; Convert an ascii byte to a nibble in [0, 15]
	;; Save ACC.
	mov b, a

	clr C
	subb a, #0x30
	mov a, b
	jc atn_out_of_range

	subb a, #0x3A
	mov a, b
	jc atn_zero_to_nine

	subb a, #0x41
	mov a, b
	jc atn_out_of_range

	subb a, #0x47
	mov a, b
	jc atn_upper

	subb a, #0x61
	mov a, b
	jc atn_out_of_range

	subb a, #0x67
	mov a, b
	jc atn_lower

	sjmp atn_out_of_range

atn_zero_to_nine:
	add a, #0xd0
	ret
atn_upper:
	add a, #0xc9
	ret
atn_lower:
	add a, #0xa9
	ret
atn_out_of_range:
	mov a, #0xFF
	ret

serial_write_byte:
;;; Writes a byte as a 2-digit hex number in ASCII.
	push ACC
	swap a
	anl a, #0x0F
	lcall nibble_to_ascii_hex
	lcall serial_write
	pop ACC
	push ACC
	anl a, #0x0F
	lcall nibble_to_ascii_hex
	lcall serial_write
	pop ACC
	ret

nibble_to_ascii_hex:
;;; Given a value in [0x0, 0xF] in ACC, write it over serial as an ASCII hex digit.
	inc a
	movc a, @a+pc
	ret
	.db "0123456789ABCDEF"

;;; END SERIAL LIBRARY
#endif
