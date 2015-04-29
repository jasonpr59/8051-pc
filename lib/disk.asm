#ifndef MIT6115_JPR_DISK_H_
#define MIT6115_JPR_DISK_H_
;;; BEGIN DISK LIBRARY
disk_init:
	lcall spi_init

	;; Set to SPI mode.
	setb SPI_SS_BAR
	mov a, #99
	lcall spi_wiggle_clock
	clr SPI_SS_BAR

	mov a, #0
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0x95 		; CRC
	lcall disk_send_command

	;; Wait for a response.
	lcall spi_poll_byte
	;; TODO(jasonpr): Check response.

	ret

disk_send_command:
	;; Send command number, with start bits.
	orl a, #0b01000000
	lcall spi_send_acc

	;; Send data.
	mov a, r0
	lcall spi_send_acc
	mov a, r1
	lcall spi_send_acc
	mov a, r2
	lcall spi_send_acc
	mov a, r3
	lcall spi_send_acc

	;; TODO(jasonpr): Calculate CRC so the client does not
	;; need to hard-code it.
	mov a, r4
	lcall spi_send_acc
	ret

;;; END DISK LIBRARY
#endif

#include <spi.asm>
