# idlab-scrod
FPGA firmware + PC software to control and readout waveform sampling ASICs for high-energy physics experiments

This repository archives the firmware (etc) for an electronics module for Belle II bPID readout.
It consists of 128 channels of 2.7GSa/s @ 12bits per sample Wilkinson ADC readout (via 16 waveform sampling ASICs), controlled by FPGAs with data streaming out over a 2.544Gbit/s LC-LC duplex fiber optic link.
An array of 16-anode micro-channel plate photomultiplier tubes (MCP-PMTs) will be mounted to detect single photoelectrons, creating an image plane with a resolution of 64*16 pixels.
Four of these modules will be mated to a highly polished quartz bar and expansion volume.
The system is able to discern the difference between high momentum kaons and pions traveling through the bar (via a folded Cherenkov image projected on the PMTs).

<img src="/wiki/images/TOP-production-boardstack.pogo-side.with-heatsinks.JPG" alt="an electronics module for Belle II bPID readout">
