  * ASIC trigger width output feedback - ensure that the trigger bits out of the ASIC remain high for long enough for us to see them in the following two items.
  * Scaler rate monitors for all trigger bits - count the number of trigger edges seen.  Counter is reset by an external signal, probably a software command.
  * Trigger data stream implementation - a running "waveform" of trigger bits, see documentation page 12 ( http://www.phys.hawaii.edu/~kurtisn/documentation/bPID_electronics/2011-09-01.BelleII-bPID.electronics-documentation.pdf )
  * Merge Xiao-Wen's temperature sensor readout into main code
  * Merge Xiao-Wen's EEPROM code to set/get SCROD ID into main code.

2011-09-15 firmware block diagram (click image to download full size version):

![![](http://idlab-scrod.googlecode.com/files/2011-09-15.SCROD-beam-test-firmware-block-diagram.whiteboard.lowres.jpeg)](http://idlab-scrod.googlecode.com/files/2011-09-15.SCROD-beam-test-firmware-block-diagram.whiteboard.jpeg)