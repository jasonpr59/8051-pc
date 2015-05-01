#!/usr/bin/env python3
"""Convert an Intel HEX file to a binary."""

import sys
import hex_format


def main(argv):
    # TODO(jasonpr): Read these paramaters from argv.
    in_file = sys.stdin
    out_buffer = sys.stdout.buffer

    # As usual, start is inclusive, end is exclusive.
    start_address = 0x8000
    end_address = 0x10000

    # Run conversion.
    program = hex_format.HexProgram(in_file)
    binary = program.as_binary()[start_address:end_address]
    out_buffer.write(binary)

if __name__ == '__main__':
    main(sys.argv)
