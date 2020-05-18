# Emu6510
Emu6510 is an experimental emulator for the 6510 family of microprocessors found in computers
such as the Commodore® 64.

## Goals
The project will be developed in three phases:
- The first phase of this project will be documented opcode emulation (no undocumented opcodes).
- The second phase will be exact cycle support.  In other words if an instruction took 7 clock
cycles on a 6510 then it will take 7 clock cycles in the emulator as well.
- The third phase will be undocumented opcodes.

## References for the 6510 microprocessor
- [C64 Programmers Reference Guide](https://www.commodore.ca/wp-content/uploads/2018/11/c64-programmers_reference_guide-05-basic_to_machine_language.pdf) starting on page 24 (232)
- [MOS 6510 Data Sheet](http://archive.6502.org/datasheets/mos_6510_mpu.pdf)

## API Documentation
Documentation of the API can be found here: [Emu6510 API](http://galenrhodes.com/Emu6510/)
