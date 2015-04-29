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
	jz diag_read_tramp
	xrl a, #'R'

	xrl a, #'W'
	jz diag_write_tramp
	xrl a, #'W'

	xrl a, #'S'
	jz diag_spi_send_tramp
	xrl a, #'S'

	xrl a, #'C'
	jz diag_sd_test_tramp
	xrl a, #'C'

	xrl a, #'M'
	jz diag_sd_msg_tramp
	xrl a, #'M'

	xrl a, #'B'
	jz diag_sd_read_block_tramp
	xrl a, #'B'
diag_cleanup:
	lcall serial_write_crlf
	sjmp diag_loop

diag_read_tramp:
	ljmp diag_read
diag_write_tramp:
	ljmp diag_write
diag_spi_send_tramp:
	ljmp diag_spi_send
diag_sd_test_tramp:
	ljmp diag_sd_test
diag_sd_msg_tramp:
	ljmp diag_sd_msg
diag_sd_read_block_tramp:
	ljmp diag_sd_read_block




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
	lcall serial_write_crlf

	lcall disk_init
	mov a, DISK_RESP_0
	lcall serial_write_byte
	mov a, DISK_RESP_1
	lcall serial_write_byte
	mov a, DISK_RESP_2
	lcall serial_write_byte
	mov a, DISK_RESP_3
	lcall serial_write_byte
	mov a, DISK_RESP_4
	lcall serial_write_byte

	ljmp diag_cleanup

diag_sd_msg:
	lcall serial_read_ascii_byte
	push acc
	lcall serial_write_byte
	lcall serial_write_crlf

	;; Load 4 bytes of args.
	lcall serial_read_ascii_byte
	push acc
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	push acc
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	push acc
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	push acc
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	push acc
	lcall serial_write_byte

	lcall serial_write_crlf

	;; Store args into registers
	pop acc
	mov r4, a
	pop acc
	mov r3, a
	pop acc
	mov r2, a
	pop acc
	mov r1, a
	pop acc
	mov r0, a
	pop acc

	;; Send command.
	lcall disk_send_command

	;; Get response.
	mov a, DISK_RESP_0
	lcall serial_write_byte
	mov a, DISK_RESP_1
	lcall serial_write_byte
	mov a, DISK_RESP_2
	lcall serial_write_byte
	mov a, DISK_RESP_3
	lcall serial_write_byte
	mov a, DISK_RESP_4
	lcall serial_write_byte

	ljmp diag_cleanup

diag_sd_read_block:
	lcall serial_write_crlf
	lcall disk_read_block
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

#include <disk.asm>
#include <serial.asm>
#include <spi.asm>
