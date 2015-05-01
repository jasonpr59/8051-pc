"""Intel HEX file utilities."""

HEX_RECORD_DATA = 0x00

class HexProgram(object):
    """A program represented by an Intel HEX file."""
    def __init__(self, open_hex_file):
        self._entries = [HexEntry.from_text(line) for line in open_hex_file]

    def as_binary(self):
        binary = bytearray(2**16)
        for entry in self._entries:
            if entry.record_type != HEX_RECORD_DATA:
                continue
            for offset, byte in enumerate(entry.data):
                binary[entry.address + offset] = byte
        return binary


class HexEntry(object):
    """A single entry in an Intel HEX file."""

    def __init__(self, address, record_type, data):
        """Create a HexEntry.
        Args:
          address: The 16-bit address where the entry begins.
          record_type: The byte-wide record type.
          data: A byte array of the data to put at the specified address.
        """
        self.address = address
        self.record_type = record_type
        self.data = data

    @classmethod
    def from_text(cls, text):
        """Make an entry corresponding to a line of text in a HEX file."""
        text = text.strip()

        start_token = text[0]
        byte_count = int(text[1:3], base=16)
        address = int(text[3:7], base=16)
        record_type = int(text[7:9], base=16)
        check_byte = int(text[-2:], base=16)

        data = list(bytes_from_ascii(text[9:-2]))
        assert len(data) == byte_count

        # Sum of all bytes must have LSB zero.
        checksum = 0
        checksum += byte_count
        checksum += address + (address >> 8)
        checksum += record_type
        checksum += sum(data)
        checksum += check_byte
        assert (checksum & 0xFF) == 0

        return cls(address, record_type, data)


def bytes_from_ascii(text):
    """Recover a sequence of bytes from its ASCII hexidecimal representaiton.
    For example:
    list(bytes_from_ascii('DEADBEEF')) == [0xDE, 0xAD, 0xBE, 0xEF].
    """
    assert len(text) % 2 == 0
    for i in range(0, len(text), 2):
        yield int(text[i:i+2], base=16)
