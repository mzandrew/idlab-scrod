

# prerequisites #

## a boardstack ##
A "front-end" module.

## a power supply ##
You need to provide DC3V, DC4V and DC5V to the boardstack.

For the carrier02 revD version of the boardstack (one SCROD, one interconnect, one carrier02), the power-on current requirements are as follows:
  * 2.90V@0.241A
  * 3.85V@0.029A (with 0 fiber transceivers installed)
  * 5.60V@0.616A
After FPGA configuration, the current draw should become:
  * 2.90V@0.836A
  * 3.85V@0.059A (with 0 fiber transceivers installed)
  * 5.60V@0.006A
After running the initialization scripts, the current draw should change to (preliminary!):
  * 2.90V@1.250A
  * 3.85V@0.216A (with 1 fiber transceiver installed)
  * 5.60V@0.616A

[elog entry #172 detailing one measurement of these currents for a full boardstack](https://www.phys.hawaii.edu/elog/iTOP-IRS3/172)

## a computer ##
Either with USB or fiber optics (SFP).

## an JTAG programmer ##
Both the xilinx "platform cable usb II" and the digilent "HS1" have been used successfully.

## an FTSW (optional) ##
This clock/trigger distribution module is optional.  Local clocking and software triggers can be used instead.

## a COPPER crate and COPPER board with processor board (optional) ##
These are optional.  USB can be used instead of this.

# get and compile the code #
```
svn checkout http://idlab-scrod.googlecode.com/svn/SCROD-boardstack/iTOP
```

## firmware ##
The firmware is located in the "IRS3B\_CRT" subdirectory of the above repository.  Xilinx ISE 13.2 has been used to successfully compile the firmware.  You will have to "regenerate cores" for each of the xco files in the ip\_cores directory.  Alternately, there is a bitfile in the "usbInterfaces" subfolder along with the readout software.

## software ##
The usb software is located in the "usbInterface" subdirectory of the above repository.  The fiber optic readout software is on the UH belleII repository (username required).  Both can compile and run under linux.  There is a README file in the root of the software repository to help you set up your build environment and compile the software.

# testing #
There are many things to test.  This section will be updated with more details and a pointer to some preliminary code.

# more details #
  * [details on data packet format from front-end to back-end (for DAQwriters)](http://www.phys.hawaii.edu/~kurtisn/doku.php?id=itop:documentation:data_format)
  * [schematics, layouts and gerber files for all PCBs](http://www.phys.hawaii.edu/~mza/PCB/index.html)

# previous versions of documentation #
Only a subset of this is still relevant:
  * [Fermilab-era version of this documentation that corresponds to the 2011 boardstack](HowToUseFrontEndElectronics.md)
  * [pdf with more detail on the Fermilab-era boardstack](http://idlab-scrod.googlecode.com/files/2011-10-16.BelleII-bPID.electronics-documentation.pdf)
  * [instructions on using the data acquisition system from 2011](http://code.google.com/p/idlab-daq/wiki/HowToUseDAQSystem)