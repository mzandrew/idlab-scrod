#!/bin/bash

#write phase bins 11 to 9, 0x0000, 0x0200, 0x0400, 0x0800
./bin/irs3BControl_writeReg 379 $((0x0200 | 0x001d ))
./bin/irs3BControl_writeReg 379 $((0x0200 | 0x009d ))
./bin/irs3BControl_writeReg 379 $((0x0200 | 0x001d ))
./bin/irs3BControl_writeReg 379 $((0x0200 | 0x011d ))
./bin/irs3BControl_writeReg 379 $((0x0200 | 0x001d ))

