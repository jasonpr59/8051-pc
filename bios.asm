;;; The BIOS.  That is, the firmware.  This program will be burned
;;; into ROM.

.EQU HEX_RECORD_DATA, 0x00
.EQU HEX_RECORD_EOF, 0x01
.EQU HEX_LOAD_ERROR, 0xFF

.EQU SERIAL_LOAD_SUCCESS, 0x00
.EQU SERIAL_LOAD_ERROR, 0xFF

.org 0x0000
	ljmp bootloader_loader

;; Addresses 0x0003 to 0x0030 are reserved for interrupt vectors.
.org 0x0030
bootloader_loader:
serial_load:
	lcall serial_init
remove_me_load:
	lcall serial_load_hex
	xrl a, SERIAL_LOAD_SUCCESS
	jz bll_serial_success
bll_serial_fail:
	mov dptr, #serial_fail_message
	lcall serial_print
	lcall serial_write_crlf
	sjmp remove_me_load
bll_serial_success:
	mov dptr, #serial_success_message
	lcall serial_print
	lcall serial_write_crlf
	ljmp bootloader 	; External label.
disk_load:
	lcall disk_init
	lcall disk_load_binary
	ljmp bootloader		; External label.

serial_load_hex:
;;; Get an Intel HEX file over serial and sets up the payload in
;;; memory.
;;; Clobbers: ACC, B, DPTR.
	mov dptr, #serial_message
	lcall serial_print
	lcall serial_write_crlf
serial_load_loop:
	lcall serial_load_hex_record
	push acc	; Save return value
	;; If record type was EOF, then we arere done.
	xrl a, #HEX_RECORD_EOF
	jz serial_load_done

	pop acc 		; Recover the return value.
	push acc
	;; If there was an error reading the record, then report it.
	xrl a, #HEX_LOAD_ERROR
	jz serial_load_error_exit

	pop acc
	;; Otherwise, laod the next record.
	sjmp serial_load_loop

serial_load_done:
	pop acc 		; Clean up the stack.
	mov a, #SERIAL_LOAD_SUCCESS
	ret
serial_load_error_exit:
	pop acc 		; Clean up the stack.
	mov a, #SERIAL_LOAD_ERROR
	ret

serial_message:
	.DB "Awaiting HEX file...", 0

serial_fail_message:
	.DB "Failed to load HEX file.", 0

serial_success_message:
	.DB "Successfully loaded HEX file.", 0

serial_load_hex_record:
;;; Load a single Intel HEX record over serial.
;;; Return the record type, or an error code, in ACC.
	;; Consume the start code, ":".
get_start_code:
	lcall serial_read
	xrl a, #':'
	;; If this was not the start code, discard it and try the next character.
	;; By looping until we get a start code, we make sure to skip any newline
	;; characters... no matter how many there are!
	;; TODO(jasonpr): Check that we only skip newlines!
	jnz get_start_code

	;; serial_read_ascii_byte_checksummed uses r0 for the checksum.
	mov r0, #0

	;; Get the record length.
	lcall serial_read_ascii_byte_checksummed
	mov r1, a

	;; Get load address.
	lcall serial_read_ascii_byte_checksummed
	mov dph, a
	lcall serial_read_ascii_byte_checksummed
	mov dpl, a

	;; Get record type.
	lcall serial_read_ascii_byte_checksummed
	mov r2, a

	;; If the record is not data (0), assume it's EOF and we're done.
	mov a, r2
	jnz serial_verify_checksum

	;; If the record has no data, jump straight to the checksum verification.
	mov a, r1
	jz serial_verify_checksum

	;; Read each byte of the program into memory.
serial_load_payload_loop:
	lcall serial_read_ascii_byte_checksummed
	movx @dptr, a
	inc dptr
	djnz r1, serial_load_payload_loop

serial_verify_checksum:
	lcall serial_read_ascii_byte_checksummed
	;; If the checksum brings us to zero,
	mov a, r0
	jz serial_verify_successful
serial_record_error:
	mov a, #HEX_LOAD_ERROR
	ret
serial_verify_successful:
	mov a, r2 		; Return the record type.
	ret

serial_read_ascii_byte_checksummed:
;;; Read an ASCII byte over serial, add it to R0, and return the
;;; original byte.
	lcall serial_read_ascii_byte
	;; Update the checksum.
	xch a, r0
	add a, r0
	xch a, r0
	;; Return the byte.
	ret

disk_load_binary:
;;; Load 512 bytes of data from the first sector of disk into memory
;;; at the bootloader address.
	;; TODO(jasonpr): Implement.
	ret

#include <address-space.asm>
#include <disk.asm>
#include <serial.asm>
