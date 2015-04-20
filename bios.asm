;;; The BIOS.  That is, the firmware.  This program will be burned
;;; into ROM.

.org 0x0000
	ljmp bootloader_loader

;; Addresses 0x0003 to 0x0030 are reserved for interrupt vectors.
.org 0x0030
bootloader_loader:
	;; If P1.0 is set, load the boot loader from disk.
	;; If P1.0 is cleared, load code over serial.
	jb P1.0, disk_load
serial_load:
	lcall serial_init
	lcall serial_load_hex
	ljmp bootloader 	; External label.
disk_load:
	lcall disk_init
	lcall disk_load_binary
	ljmp bootloader		; External label.

serial_load_hex:
;;; Get an Intel HEX file over serial and sets up the payload in
;;; memory.
	;; TODO(jasonpr): Implement.
	ret

disk_load_binary:
;;; Load 512 bytes of data from the first sector of disk into memory
;;; at the bootloader address.
	;; TODO(jasonpr): Implement.
	ret

#include <address-space.asm>
#include <disk.asm>
#include <serial.asm>
