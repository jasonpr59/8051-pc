class Cpu8051(object):
    def __init__(self):
        self.carry = False
        self.accumulator = 0x00

    def rlc(self):
        self.accumulator <<= 1
        self.accumulator |= self.carry
        self.carry = bool(self.accumulator >> 8)
        self.accumulator &= 0xFF

    def add_acc(self, value):
        self.accumulator += value
        self.carry = bool(self.accumulator & 0x100)
        self.accumulator &= 0xFF

    def xor_acc(self, value):
        self.accumulator ^= value

def bit_stream(byte_stream):
    """ Yields bits (bools) of each byte, from MSB to LSB.
        Args:
            byte_stream: A sequence of bytes.
    """
    for byte in byte_stream:
        for offset in range(8):
            yield bool((byte << offset) & 0x80)

def advance_crc(cpu, bit):
    cpu.carry = bit
    if cpu.carry:
        # XOR the MSB with 1.
        cpu.add_acc(0x80)
    cpu.carry = False
    cpu.rlc()
    if cpu.carry:
        cpu.xor_acc(0b00010010)

def sd_crc(byte_stream):
    cpu = Cpu8051()
    for bit in bit_stream(byte_stream):
        advance_crc(cpu, bit)
    return cpu.accumulator

def main():
    crc = sd_crc([0x11, 0x00, 0x00, 0xff, 0x01])
    print '0x%02x' % (crc >> 1)

if __name__ == '__main__':
    main()
