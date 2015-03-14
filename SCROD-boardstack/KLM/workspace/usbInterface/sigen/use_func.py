#!/usr/bin/env python
#Following command will print documentation of use_func.py:
#pydoc use_func  

"""
OVERVIEW:
May be used to determine where delay is coming from

AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

DESCRIPTION:
Script used to control Rigol DG4162
"""


# python tx_func.py 1 0 2 2

from rigol_DG4162 import * 
import sys


# GLOBAL VARIABLES
AMPLITUDE = '400e-03'  # 1 Vpp was no good.... use 400mVpp
OFFSET = '0'	    # 500 mV offset was for 0 Ohm Res 
FREQUENCY = '50e06' # 50MHz
BURST_ON_OFF = 'OFF'


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    CYAN = '\033[96m'
    BROWN = '\033[33m'


if len(sys.argv) != 5:
    print "wrong number of arguments: usage \nipython tx_func.py <Func"+\
	" Channel: 1, 2> <Func Output: 0= 'OFF', 1= 'ON'> <Burst Cycles: pos integer> <Burst Delay: usec(s)>"
    sys.exit()

channel = sys.argv[1]
try:
    if (int(channel) == 1) or (int(channel) == 2):
        pass
    else:
        print bcolors.FAIL+"\t>> Error!!! Channel must be 1 or 2!"+\
            bcolors.ENDC
        sys.exit()
except ValueError:
    print bcolors.FAIL+"\t>> Error!!! Channel must be 1 or 2!"+\
        bcolors.ENDC
    sys.exit()

on_or_off = sys.argv[2].upper()  # Cmd to turn function gen on/off
cycles = sys.argv[3]  # numb of cycles for sinusoid
delay = sys.argv[4]   # delay in sec(s)


# Make Instrument Object
func = Rigol_DG4162("192.168.153.79", None)
id=func.identification()
print bcolors.HEADER+"\n"+id+bcolors.ENDC

# Initialize Settings of Rigol
func.channel = channel # change to channel 1
func.function = 'sinusoid'
func.output = 'off'
func.output_polarity = 'NORMAL'
func.output_load = 50
func.burst = BURST_ON_OFF 
func.voltage_unit='VPP'
func.amplitude = AMPLITUDE
func.frequency = FREQUENCY
func.offset = OFFSET
func.burst_delay = delay
func.burst_cycles = cycles


# Turning function generator on or off
if (on_or_off == '0') or (on_or_off == 'OFF'):
    #func.amplitude = 0
    func.output = 'OFF'
    print bcolors.OKBLUE+"-> Turning Function Generator Off!"+bcolors.ENDC
    print bcolors.OKBLUE+"-> Start taking new pedestal data..."+bcolors.ENDC
elif (on_or_off == '1') or (on_or_off == 'ON'):
    #func.amplitude = '350e-03'
    func.amplitude = AMPLITUDE
    func.output = 'ON'
    print bcolors.OKGREEN+"-> New pedestals were generated..."+bcolors.ENDC
    print bcolors.OKGREEN+"-> Turning Function Generator On!"+bcolors.ENDC
else:
    print bcolors.FAIL+"Error!!! <Func Output: 0= 'OFF', 1= 'ON'>"+bcolors.ENDC
    sys.exit()




