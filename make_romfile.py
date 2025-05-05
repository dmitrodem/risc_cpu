#!/usr/bin/env python3

import click


@click.command()
@click.argument("romfile", type=click.File("w"))
def main(romfile):
    lines = ["0000" for i in range(256)]
    for i in range(16):
        opcode = (0b0100 << 12) | ((0x10 | i) << 4) | i
        lines[i] = f"{opcode:04x}"
    opcode = (0b0100 << 12) | ((0xab) << 4) | 0
    lines[16] = f"{opcode:04x}"
    opcode = (0b0101 << 12) | ((0) << 4) | 0
    lines[17] = f"{opcode:04x}"
    romfile.write("\n".join(lines))


if __name__ == "__main__":
    main()
