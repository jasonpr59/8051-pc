#ifndef MIT6115_JPR_DISK_H_
#define MIT6115_JPR_DISK_H_
;;; BEGIN DISK LIBRARY

.EQU DISK_RESP_0, 0x70
.EQU DISK_RESP_1, 0x71
.EQU DISK_RESP_2, 0x72
.EQU DISK_RESP_3, 0x73
.EQU DISK_RESP_4, 0x74

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

	mov a, DISK_RESP_0
	ret

disk_cmd8:
	mov a, #8
	mov r0, #0
	mov r1, #0
	mov r2, #1
	mov r3, #0xAA
	mov r4, #0x87		; CRC
	lcall disk_send_command

disk_begin_app_cmd:
;;; Send CMD55 (the prefix for ACMDs).
	mov a, #55
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0xF1
	lcall disk_send_command
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


	;; Get response.
	lcall spi_poll_byte
	mov DISK_RESP_0, a
	lcall spi_read_byte
	mov DISK_RESP_1, a
	lcall spi_read_byte
	mov DISK_RESP_2, a
	lcall spi_read_byte
	mov DISK_RESP_3, a
	lcall spi_read_byte
	mov DISK_RESP_4, a

	;; Read one past the end, to give the chip some time.
	;; TODO(jasonpr): Cite evidence that this is right.
	lcall spi_read_byte

	ret

;;; END DISK LIBRARY
#endif

#include <spi.asm>
