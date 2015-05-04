#ifndef MIT6115_JPR_DISK_H_
#define MIT6115_JPR_DISK_H_
;;; BEGIN DISK LIBRARY

.EQU DISK_RESP_0, 0x70
.EQU DISK_RESP_1, 0x71
.EQU DISK_RESP_2, 0x72
.EQU DISK_RESP_3, 0x73
.EQU DISK_RESP_4, 0x74

.EQU DISK_IDLE_BIT, 0xE0	; ACC.0

.EQU BLOCK_BUFFER, 0xF000
disk_init:
	lcall spi_init

	;; Set to SPI mode.
	setb SPI_SS_BAR
	mov a, #10
	lcall spi_wiggle_clock
	clr SPI_SS_BAR

	;; TODO(jasonpr): Check results!
	lcall disk_cmd0
	lcall disk_cmd8
	lcall disk_activate

	ret


disk_cmd0:
	mov a, #0
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	lcall disk_send_command

disk_cmd8:
	mov a, #8
	mov r0, #0
	mov r1, #0
	mov r2, #1
	mov r3, #0xAA
	lcall disk_send_command
	ret

disk_send_op_cond:
;;; Send ACMD41.
	lcall disk_begin_app_cmd

	mov a, #41
	mov r0, #0x40
	mov r1, #0
	mov r2, #0
	mov r3, #0
	lcall disk_send_command
	ret

disk_begin_app_cmd:
;;; Send CMD55 (the prefix for ACMDs).
	mov a, #55
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	lcall disk_send_command
	ret

disk_send_command:
	push acc

	;; Send command number, with start bits.
	orl a, #0b01000000
	lcall spi_send_acc

	;; At the moment, ACC and R0 through R3 contain the
	;; values we are sending.  Compute the CRC!
	lcall disk_calculate_crc
	mov r4, a

	;; Send data.
	mov a, r0
	lcall spi_send_acc
	mov a, r1
	lcall spi_send_acc
	mov a, r2
	lcall spi_send_acc
	mov a, r3
	lcall spi_send_acc

	;; Send the CRC we calculated above.
	mov a, r4
	lcall spi_send_acc

	;; Get response.
	lcall disk_poll_response_byte
	mov DISK_RESP_0, a

	;; If CMD8 or CMD58, get the rest of the response (four more
	;; bytes).
	pop acc
	xrl a, #8
	jz read_remaining_response
	xrl a, #0x32 		; Un-XOR with 8, then XOR with 58
	jz read_remaining_response
	sjmp read_response_end

read_remaining_response:
	lcall spi_read_byte
	mov DISK_RESP_1, a
	lcall spi_read_byte
	mov DISK_RESP_2, a
	lcall spi_read_byte
	mov DISK_RESP_3, a
	lcall spi_read_byte
	mov DISK_RESP_4, a

read_response_end:
	;; Read one past the end, to give the chip some time.
	;; TODO(jasonpr): Cite evidence that this is right.
	lcall spi_read_byte

	ret

disk_activate:
;;; Send ACMD41 until the card exits the idle state.
;;; (Could take hundreds of milliseconds!)
	;; TODO(jasonpr): Add a timeout.
	lcall disk_send_op_cond
	mov a, DISK_RESP_0
	jb DISK_IDLE_BIT, disk_activate

	;; When we get here, the disk is no longer idle.
	ret

disk_read_block:
;;; Read SD card block at [r0..r3] (512 bytes) into memory
;;; at [0xF000, 0xF1FF].
	push dph
	push dpl
	;; Send CMD17: Read Block.
	mov a, #17
	;; R0 through R3 were set by the caller.
	lcall disk_send_command

	mov r0, #20

	lcall disk_poll_data_token

	mov r0, #2
	mov r1, #0
disk_block_read_loop:
	lcall spi_read_byte
	movx @dptr, a
	inc dptr
	djnz r1, disk_block_read_loop
	djnz r0, disk_block_read_loop

	;; TODO(jasonpr): Verify checksum.
	lcall spi_read_byte
	lcall spi_read_byte

	;; TODO(jasonpr): Do I need to read a padding byte?
	pop dpl
	pop dph
	ret

disk_poll_response_byte:
;;; Read a SPI byte that starts with zero.
	lcall spi_read_byte
	jb acc.7, disk_poll_response_byte
	ret

disk_poll_data_token:
;;; Read SPI bytes until we get 0xFE, the data token for
;;; CMD17, CMD18, and CMD24.
	lcall spi_read_byte
	xrl a, #0xFE
	jnz disk_poll_data_token
	ret

disk_calculate_crc:
	;; Initaialize ACC to zero... but not before we pull the
	;; byte out of it!
	mov b, a
	clr a
	lcall crc_fold_byte

	mov b, r0
	lcall crc_fold_byte

	mov b, r1
	lcall crc_fold_byte

	mov b, r2
	lcall crc_fold_byte

	mov b, r3
	lcall crc_fold_byte

	orl a, #0x01
	ret

;;; END DISK LIBRARY
#endif

#include <crc.asm>
#include <spi.asm>
