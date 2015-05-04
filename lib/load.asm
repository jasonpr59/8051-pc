#ifndef MIT6115_JPR_LOAD_H_
#define MIT6115_JPR_LOAD_H_
;;; BEGIN LOAD LIBRARY
;;; This library contains utilities for loading data from a filesystem
;;; into memory.

load_fat32_to_ram:
;;; Given a file at a path specified by the string at DPTR,
;;; read it to [0x8000, 0xFFFF].
;;; TODO(jasonpr): Make this more general.
;;; Requires that the FAT32 filesystem has alread been mounted.
	;; Save the parameters-- they'll be clobbered when we read the
	;; root dir.
	push dph
	push dpl

	mov dptr, #0xF000
	lcall fat32_read_root_dir

	;; Recover the filename pointer.
	pop dpl
	pop dph
	;; The filename length is always 11.
	mov r0, #11 		; 8-char name, 3-char extension.

	lcall fat32_find_file_in_dir
	;; TODO(jasonpr): Verify it was found.
	lcall fat32_cluster_start

	;; Start pouring bytes into this spot in RAM.
	mov dptr, #0x8000
load_sector:
	mov a, #'.'
	lcall serial_write

	lcall fat32_read_sector
	;; Advance dptr by 512 bytes.
	inc dph
	inc dph
	lcall inc_32bit_low

	;; If dph overflows, we've read everything.
	mov a, dph
	jnz load_sector
	ret

;;; END LOAD LIBRARY
#endif

#include <instr.asm>
#include <string.asm>
