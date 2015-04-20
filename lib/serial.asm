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

;;; END SERIAL LIBRARY
#endif
