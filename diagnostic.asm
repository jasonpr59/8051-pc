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

	xrl a, #'P'
	jz diag_print_mem_page_tramp
	xrl a, #'P'

	xrl a, #'Y'
	jz diag_crc_tramp
	xrl a, #'Y'

	xrl a, #'A'
	jz diag_arith_tramp
	xrl a, #'A'

	xrl a, #'F'
	jz diag_fat_tramp
	xrl a, #'F'

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
diag_print_mem_page_tramp:
	ljmp diag_print_mem_page
diag_crc_tramp:
	ljmp diag_crc
diag_arith_tramp:
	ljmp diag_arith
diag_fat_tramp:
	ljmp diag_fat

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

	lcall serial_write_crlf

	;; Store args into registers
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
	lcall serial_read_ascii_byte
	mov r0, a
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	mov r1, a
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	mov r2, a
	lcall serial_write_byte
	lcall serial_read_ascii_byte
	mov r3, a
	lcall serial_write_byte
	lcall serial_write_crlf

	lcall disk_read_block
	ljmp diag_cleanup

diag_print_mem_page:
	lcall serial_read_ascii_byte
	mov dph, a
	mov dpl, #0
	lcall serial_write_byte
	lcall serial_write_crlf

	mov r0, #0
diag_print_page_loop:
;; Print a newline before every 16 bytes.
	mov a, r0
	anl a, #0xF
	jnz diag_print_no_newline
	lcall serial_write_crlf
diag_print_no_newline:
	movx a, @dptr
	lcall serial_write_byte
	lcall serial_write_space
	inc dptr
	djnz r0, diag_print_page_loop

	ljmp diag_cleanup

diag_crc:
	lcall serial_read_ascii_byte
	mov r0, acc
	lcall serial_write_byte

	lcall serial_read_ascii_byte
	mov r1, acc
	lcall serial_write_byte
	lcall serial_write_crlf

	clr a
	mov b, r0
	lcall crc_fold_byte
	mov b, r1
	lcall crc_fold_byte

	lcall serial_write_byte
	ljmp diag_cleanup

diag_arith:
	lcall serial_write_crlf

	mov r0, #0x21
	mov r1, #0x43
	mov r2, #0x65
	mov r3, #0x87

	mov r4, #0xA9

	lcall mul_32by8bit

	mov a, r4
	lcall serial_write_byte
	mov a, r3
	lcall serial_write_byte
	mov a, r2
	lcall serial_write_byte
	mov a, r1
	lcall serial_write_byte
	mov a, r0
	lcall serial_write_byte

	ljmp diag_cleanup

diag_fat:
	lcall serial_write_crlf
	lcall fat32_init
	;; Read first sector of root dir into disk buffer.
	;; This is a listing of 16 files or folders.
	lcall fat32_read_root_dir
	;; Find the file with the specified name.  Put its
	;; cluster number into r[3:0].  Indicate success in ACC.
	mov dptr, #boot_file_name
	mov r0, #11 		; 8 chars for name + 3 for extension
	lcall fat32_find_file_in_dir
	lcall serial_write_byte	; Print success value.
	lcall serial_write_crlf
	lcall serial_write_dword ; Print cluster number.
	lcall fat32_cluster_start
	lcall fat32_read_sector
	ljmp diag_cleanup
boot_file_name:
	.db "HELLO   TXT", 0

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

#include <crc.asm>
#include <disk.asm>
#include <fat32.asm>
#include <math.asm>
#include <serial.asm>
#include <spi.asm>
