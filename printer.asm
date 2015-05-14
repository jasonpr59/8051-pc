#include <address-space.asm>

.ORG 0x800B
	cpl P1.2
	reti

.ORG OS_ADDR
main:
	lcall serial_init
	mov dptr, #hello_message
	lcall serial_print

	lcall setup_timer

end_loop:
	sjmp end_loop

setup_timer:
	anl TMOD, #0F0h  ; Clear Timer 0 Control.
	orl TMOD, #02h  ; Set Timer 0 to Mode 2: 8-bit auto-reload.

	; Set the frequency.
	mov TH0, #0x80

	; Enable timer interupts.
	setb EA
	setb ET0

	; Start timing!
	setb TR0

	ret


hello_message:
	.db "Jason Paller-Rzepka's 6.115 Final Project:\r\n"
	.db "SD Bootloader and Text-Mode Monitor.\r\n"
	.db "\r\n"
	.db "The following 8051 software libraries were written for this project:\r\n"
	.db "  1. Bit-banged SPI\r\n"
	.db "  2. SD over SPI (initialization and reading)\r\n"
	.db "  3. CRC computation for the SD protocol\r\n"
	.db "  4. Basic FAT32 mounting/reading\r\n"
	.db "  5. Limited 32-bit math, for FAT32\r\n"
	.db "\r\n"
	.db "The PSoC was configured as a 80x25 character serial terminal, which outputs 640x480 VGA at 70Hz.\r\n"
	.db "\r\n"
	.db "Additionally, the following hardware was setup:\r\n"
	.db "  1. Memory space manager using 22V10.\r\n"
	.db "  2. RAM and ROM chips on breadbord.\r\n"
	.db "  3. Auxiliary chips to produce a von Neumann-style RD# signal.\r\n"
	.db "\r\n"
	.db "I would recommend avoiding the Intel 8042 chip.\r\n"
	.db 0

#include <serial.asm>
