#ifndef MIT6115_JPR_FAT32_H_
#define MIT6115_JPR_FAT32_H_
;;; BEGIN FAT32 LIBRARY

.EQU VOLUME_BEGIN, 0xFF00
.EQU SECTORS_PER_CLUSTER, 0xFF04
.EQU RESERVED, 0xFF08
.EQU SECTORS_PER_FAT, 0xFF0C
.EQU ROOT_SECTOR_INDEX, 0xFF10
.EQU CLUSTERS_START, 0xFF14

fat32_init:
	;; Read MBR.
	mov r3, #0
	mov r2, #0
	mov r1, #0
	mov r0, #0
	lcall disk_read_block

	;; Read volume ID.
	mov dptr, #0xF1C6
	lcall load_32bit_low
	mov dptr, #VOLUME_BEGIN
	lcall store_32bit_low

	lcall endian_swap
	lcall disk_read_block

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

fat32_read_root_dir:
	;; Calculate root dir sector.
	;; Read sector.
	ret

fat32_get_file_location:
;;; Return the sector count.  Put the sector number at DPTR,
;;; MSB first.
	ret

;;; END FAT32 LIBRARY
#endif
