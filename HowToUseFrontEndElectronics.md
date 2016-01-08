# Introduction #

A thorough description of the electronics and system for 2011 cosmic / beam test is available here:  [Belle II bPID electronics documentation](http://code.google.com/p/idlab-scrod/wiki/BelleIIbPIDElectronicsDocumentation)

# Hardware #

A hardware setup guide is now available here: [Hardware Setup Guide](http://idlab-scrod.googlecode.com/files/bPID_Electronics_Setup.pdf)

### board stack ###

A board stack consists of a SCROD, an interconnect board, four ASIC carrier boards, 16 ASIC daughtercards, a front-back board, a front-front board and an SL10\_HV board.

### SCROD ###

SCROD is the controller of the board stack.  It has an FPGA and connectors for communication to other boards.

### ASIC daughtercards ###

The ASIC that will be used for the 2011 cosmic / beam test is the IRS2.  The daughtercards on which the ASICs sit is called the IRS2\_DC revB.  That board has 8 amplifiers (one for each ASIC input channel) and 16 DAC channels to control various aspects of the ASICs' functionality.

### power ###

A fully populated board stack requires 4V @ 6A through a 4 pin molex connector.

# FPGA firmware #

### subversion repository ###

If you want to keep up-to-date on the firmware or build it yourself, you need to checkout a copy of the subversion repository.  The following are command-line instructions on how to do so:

```
mkdir idlab-scrod
cd idlab-scrod
svn checkout http://idlab-scrod.googlecode.com/svn/iTOP-BLAB3A-boardstack/branches
```

The main .xise project file is in "idlab-scrod/branches/beam\_test\_or\_bust/ise-project/" and is called, "beam\_test\_or\_bust.xise".

Some .xco files must be re-added to the project after opening it in Xilinx ISE (they are in "idlab-scrod/branches/beam\_test\_or\_bust/ise-project/ipcore\_dir/" and "idlab-scrod/branches/pseudo-data\_by\_fiber/ise-project/ipcore\_dir/"), and "ip cores" must be regenerated or the compilation will fail.

All current code (for 2011 beam-test) lies in "branches/beam\_test\_or\_bust" and "branches/pseudo-data\_by\_fiber".

To keep up-to-date with the latest changes, run the following from the "idlab-scrod/branches" directory:
```
svn update
```

After running "svn update", you must recompile the project (although .xco files need not be re-added and ip cores need not be regenerated).

### JTAG programmer ###

A JTAG programmer is used to send a program to the FPGA on SCROD.  Before this is done, the FPGA does not perform any useful functions.

### IMPACT ###

IMPACT is a Xilinx ISE / Xilinx Labtools program to send a .bit file to an FPGA.

### Chipscope ###

Chipscope is a Xilinx ISE / Xilinx Labtools program to allow communication with the internal workings of the FPGA in real-time while the FPGA program is active.

# DAQ #

See [HowToUseDAQSystem](http://code.google.com/p/idlab-daq/wiki/HowToUseDAQSystem) for information on how to gather data from a front-end electronics module.