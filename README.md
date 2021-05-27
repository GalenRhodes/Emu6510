# Emu6510

Emu6510 is an experimental emulator for the 6510 family of microprocessors found in computers
such as the Commodore® 64.

## Goals

The project will be developed in four phases:

1) ~~Documented opcode emulation - no undocumented opcodes.~~ - _Done_.
2) ~~Frequency emulation - throttling down to 1-2 Mhz.~~ - _Done_.
3) ~~Exact cycle support.  In other words if an instruction took 7 clock
cycles on a 6510 then it will take 7 clock cycles in the emulator as well.~~ - _Done_.
4) ~~Undocumented opcodes.~~ - *Done.*

Currently, the only thing supported is the emulation of the processor itself.  The further emulation of an entire machine, such as, say, a Commodore® 64, is still remaining to be done.  This may take a while.

The first goal of this project is to emulate a Commodore® 1541/1571/1581 disk drive on an [ODROID® H2](https://www.hardkernel.com/shop/odroid-h2plus/).

## Learning Resources

The following websites were used as excellent resources for learning to write an emulator.

- [emulator101.com - 6502 emulator](http://www.emulator101.com/6502-emulator.html)
- [the 6502 microprocessor resource](http://www.6502.org)
- [6502/6510/8500/8502 Opcodes](http://galenrhodes.com/Emu6510/Other/6502_6510_8500_8502%20Opcodes.html)
- [Extra Instructions Of The 65XX Series CPU](http://galenrhodes.com/Emu6510/Other/Extra%20Instructions%20Of%20The%2065XX%20Series%20CPU.html)

## References for the 6510 microprocessor

- [C64 Programmers Reference Guide](https://www.commodore.ca/wp-content/uploads/2018/11/c64-programmers_reference_guide-05-basic_to_machine_language.pdf) starting on page 24 (232)
- [MOS 6510 Data Sheet](http://archive.6502.org/datasheets/mos_6510_mpu.pdf)

## API Documentation

Documentation of the API can be found here: [Emu6510 API](http://galenrhodes.com/Emu6510/)

