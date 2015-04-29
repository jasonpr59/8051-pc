#ifndef MIT6115_JPR_SPI_H_
#define MIT6115_JPR_SPI_H_
;;; BEGIN SPI LIBRARY

.EQU SPI_CLK, 0x94
.EQU SPI_MOSI, 0x95
.EQU SPI_SS_BAR, 0x96
.EQU SPI_MISO, 0x97

spi_init:
	clr SPI_CLK		; CPOL = 0.
	setb SPI_MISO		; Set MISO pin to input mode.
	clr SPI_SS_BAR		; Activage the slave.
	setb SPI_MOSI		; Keep MOSI high when not in use.
	ret

spi_send_acc_msb:
;;; Send the bit in ACC.0 over SPI.
	jb acc.7, spi_send_logic_one
	;; Send a logic zero.
	clr SPI_MOSI
	sjmp spi_bit_ready
spi_send_logic_one:
	setb SPI_MOSI
	sjmp spi_bit_ready
spi_bit_ready:
	setb SPI_CLK
	nop
	nop
	clr SPI_CLK
	ret

spi_send_acc:
;;; Send all eight bits in ACC over SPI.
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a
	lcall spi_send_acc_msb
	rl a

	ret

spi_wiggle_clock:
;;; Toggles the clock for ACC bytes.
;;; Nukes ACC.
;;; Requires ACC > 0.
	mov b, #16
spi_half_wiggle:
	cpl SPI_CLK
	djnz b, spi_half_wiggle
	;; DJNZ provides delay, so no NOPs.
	djnz acc, spi_wiggle_clock

	ret

spi_read_bit_acc_lsb:
	setb SPI_CLK
	nop
	nop
	jb SPI_MISO, spi_recv_logic_one
	;; Receive a logic zero
	clr acc.0
	sjmp spi_bit_received
spi_recv_logic_one:
	setb acc.0
spi_bit_received:
	clr SPI_CLK
	ret

spi_read_byte:
;;; Read a SPI byte.
;;; Assumes the slave is ready to send data immediately.
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	rl a
	lcall spi_read_bit_acc_lsb
	ret

;;; END SPI LIBRARY
#endif
