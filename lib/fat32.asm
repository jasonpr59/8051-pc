#ifndef MIT6115_JPR_FAT32_H_
#define MIT6115_JPR_FAT32_H_
;;; BEGIN FAT32 LIBRARY

.EQU VOLUME_BEGIN, 0xFF00
.EQU SECTORS_PER_CLUSTER, 0xFF04
.EQU RESERVED, 0xFF08
.EQU SECTORS_PER_FAT, 0xFF0C
.EQU ROOT_SECTOR_INDEX, 0xFF10
.EQU CLUSTERS_START, 0xFF14

.EQU ENTRY_CLUSTER_BYTE0_OFFSET, 26
.EQU ENTRY_CLUSTER_BYTE1_OFFSET, 27
.EQU ENTRY_CLUSTER_BYTE2_OFFSET, 20
.EQU ENTRY_CLUSTER_BYTE3_OFFSET, 21

fat32_init:
	;; Read MBR.
	mov r3, #0
	mov r2, #0
	mov r1, #0
	mov r0, #0
	mov dptr, #BLOCK_BUFFER
	lcall disk_read_block

	;; Read volume ID.
	mov dptr, #0xF1C6
	lcall load_32bit_low
	mov dptr, #VOLUME_BEGIN
	lcall store_32bit_low
	mov dptr, #BLOCK_BUFFER
	lcall fat32_read_sector

	;; Calculate volume parameters.
	;; Sectors per cluster
	mov dptr, #0xF00D
	movx a, @dptr
	mov dptr, #SECTORS_PER_CLUSTER
	movx @dptr, a

	;; Num reserved
	mov dptr, #0xF00E
	lcall load_32bit_low
	mov r2, #0
	mov r3, #0
	mov dptr, #RESERVED
	lcall store_32bit_low

	;; Sectors per FAT
	mov dptr, #0xF024
	lcall load_32bit_low
	mov dptr, #SECTORS_PER_FAT
	lcall store_32bit_low

	;; Root cluster index.
	mov dptr, #0xF02C
	lcall load_32bit_low
	mov dptr, #ROOT_SECTOR_INDEX
	lcall store_32bit_low

	;; Calculate sector at which clusters start.
	;; 	CLUSTERS_START = VOLUME_BEGIN + RESERVED + SECTORS_PER_FAT +
	;;	                 SECTORS_PER_FAT
	;; (There are two FATs, so two SECTORS_PER_FAT terms.)
	mov dptr, #VOLUME_BEGIN
	lcall load_32bit_low
	mov dptr, #RESERVED
	lcall load_32bit_high
	lcall sum_32bit

	mov dptr, #SECTORS_PER_FAT
	lcall load_32bit_high
	lcall sum_32bit		; First FAT.
	lcall sum_32bit 	; Secont FAT.

	mov dptr, #CLUSTERS_START
	lcall store_32bit_low 	; Store the sum.
	ret

fat32_cluster_start:
;;; Get start sector number of the cluster in r[3:0].
;;; Write the result into r[3:0], clobbering the input.
	;; Do output_sector =
	;; (input_cluster - 2) * SECTORS_PER_CLUSTER + CLUSTERS_START

	;; Adding 0xFFFFFFFE is easier than subtracting 2.
	mov r4, #0xFE
	mov r5, 0xFF
	mov r6, 0xFF
	mov r7, 0xFF
	lcall sum_32bit

	mov dptr, #SECTORS_PER_CLUSTER
	movx a, @dptr
	mov r4, a
	lcall mul_32by8bit

	mov dptr, #CLUSTERS_START
	lcall load_32bit_high
	lcall sum_32bit

	ret

fat32_read_root_dir:
;;; Read the first sector of the root dir's fist cluster from disk.
	;; Calculate root dir sector.
	;; Read root sector.
	mov dptr, #ROOT_SECTOR_INDEX
	lcall load_32bit_low
	lcall fat32_cluster_start
	mov dptr, #BLOCK_BUFFER
	lcall fat32_read_sector
	;; TODO(jasonpr): Maybe save the cluster start so we can
	;; access the FAT later.
	ret

fat32_find_file_in_dir:
;;; Find the cluster number of the file that's in the currently
;;; loaded sector.
;;; Assumes the current sector is part of a directory listing,
;;; and that this sector lists the named file.
;;; The file name is passed in dptr.
;;; The file name's length is passed in r0.
;;; The 32-bit result goes in r[3:0].
;;; Returns #0 for success, #0xFF for failure (in ACC).
;;; TODO(jasonpr): Relax these crazy restrictions!
	;; Let dptr76 have the target filename, and dptr
	;; have the current candidate.
	lcall swap_dptrs
	mov dptr, #0xF000
	;; Let r1 contain the number of candidates left.
	mov r1, #16
fat32_find_file_attempt:
	;; Check if the currently listing is for the target filename.
	lcall string_equal
	jz fat32_find_file_advance
	;; We got it!  Find the cluster and return.
	;; dptr points at the entry.
	mov a, #ENTRY_CLUSTER_BYTE0_OFFSET
	movc a, @a + dptr
	mov r0, a
	mov a, #ENTRY_CLUSTER_BYTE1_OFFSET
	movc a, @a + dptr
	mov r1, a
	mov a, #ENTRY_CLUSTER_BYTE2_OFFSET
	movc a, @a + dptr
	mov r2, a
	mov a, #ENTRY_CLUSTER_BYTE3_OFFSET
	movc a, @a + dptr
	mov r3, a
	mov a, #0		; Success!
	ret
fat32_find_file_advance:
	mov a, dpl
	add a, #0x20
	mov dpl, a
	mov a, dph
	addc a, #0
	mov dph, a
	djnz r1, fat32_find_file_attempt
	;; Done advancing, still haven't found file.
	mov a, #0xFF 		; Failure code.
	ret

fat32_get_file_location:
;;; Return the sector count.  Put the sector number at DPTR,
;;; MSB first.
	ret

fat32_read_sector:
;;; Read the sector with the number in r[3:0].
;;; This function exists mostly to bridge FAT endianness with
;;; SD endianness.
	;; Save r[3:0].
	mov a, r0
	push acc
	mov a, r1
	push acc
	mov a, r2
	push acc
	mov a, r3
	push acc

	lcall endian_swap
	lcall disk_read_block

	;; Restore r[3:0].
	pop acc
	mov r3, a
	pop acc
	mov r2, a
	pop acc
	mov r1, a
	pop acc
	mov r0, a

	ret

;;; END FAT32 LIBRARY
#endif

#include <instr.asm>
#include <math.asm>
#include <string.asm>
