#include <address-space.asm>

;;; We can replace the bootloader with a diagnostic program, whose
;;; job is to help us investigate the hardware without loading the OS.
;;; It functions much like MINMON did.

.ORG BOOTLOADER_ADDR
diagnostic:
	lcall serial_init
	lcall spi_init

diag_loop:
	mov dptr, #diag_prompt
	lcall serial_print

	lcall serial_read
	clr ACC.5 		; capitalize it
	lcall serial_write

	xrl a, #'R'
	jz diag_read
	xrl a, #'R'

	xrl a, #'W'
	jz diag_write
	xrl a, #'W'

	xrl a, #'S'
	jz diag_spi_send
	xrl a, #'S'

	xrl a, #'C'
	jz diag_sd_test
	xrl a, #'C'

diag_cleanup:
	lcall serial_write_crlf
	sjmp diag_loop


diag_read:
	lcall diag_get_address
	movx a, @dptr
	lcall serial_write_byte
	ljmp diag_cleanup

diag_write:
	lcall diag_get_address

	mov a, #'='
	lcall serial_write

	lcall serial_read_ascii_byte
	movx @dptr, a
	lcall serial_write_byte

	ljmp diag_cleanup

diag_spi_send:
	lcall serial_read_ascii_byte
	lcall serial_write_byte
	lcall spi_send_acc
	ljmp diag_cleanup

diag_sd_test:
	;; Prepare to accept initial command.
	setb SPI_SS_BAR
	mov a, #99
	lcall spi_wiggle_clock
	clr SPI_SS_BAR

	;; It is command #0, reset.
	mov a, #0b01000000
	lcall spi_send_acc

	;; Its argument is 32-bit zero.
	mov a, #0
	lcall spi_send_acc
	lcall spi_send_acc
	lcall spi_send_acc
	lcall spi_send_acc

	;; Send the CRC and end bit.
	mov a, #0x95
	lcall spi_send_acc

	;; Wait for a response.
	mov a, #99
	lcall spi_wiggle_clock

	ljmp diag_cleanup

diag_get_address:
;;; Read a 16-bit address over serial into dptr.
;;; Echo the received bytes.
;;; Clobbers ACC.
	;; Read Most Significant Byte.
	lcall serial_read_ascii_byte
	mov dph, a
	lcall serial_write_byte

	;; Read Least Significant Byte.
	lcall serial_read_ascii_byte
	mov dpl, a
	lcall serial_write_byte
	lcall serial_write_crlf

	ret

diag_prompt:
	.DB "diag> ", 0

#include <serial.asm>
#include <spi.asm>
