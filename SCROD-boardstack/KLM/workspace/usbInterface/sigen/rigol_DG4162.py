#!/usr/bin/env python
#Following command will print documentation of rigol_DG4162.py:
#pydoc rigol_DG4162 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
Python wrapper for commands to control an Instrument called:
RIGOL DG4162 Function/Arbitrary Waveform Generator
 
HOW TO USE:
"from rigol_DG4162 import Func_DG4162" will import the class
"func = Rigol_DG4162(addr)" will create the instrument object
"func.channel = 2" will set channel to chan 2 (IMPORTANT: Set chan 1st)
"func.set_voltage = 5" will set voltage to 5 Volts on channel 2
"print func.set_voltage" will read the set voltage on chan 2

RIGOL DG4162 Function/Arbitrary Waveform Generator USER MANUAL:
http://micromir.ucoz.ru/Generator/Rigol/DG4000_UserGuide.pdf
"""


from link import *

# Controlling this function generator 
class Rigol_DG4162(object):
    def __init__(self, addr=None, port=None):
        ''' Input:  addr is a string for RS232 or IP which is 192.168.#.#
            Output: returns nothing, but initializes connection  '''
        addr=addr.upper()
        #Set up link connection. Either RS232 via USB or GPIO via Ethernet
        if (addr == 'RS232') or (addr == 'RS-232'):
            self.link = RS232()
        elif (addr != None) and (port == None):
            self.link = Ethernet(addr)
        elif (addr != None) and (port != None):
            self.link = Ethernet_Controller(addr,port)
        else:
            print "Invalid address: "+str(addr)
   
 
    def _binary_cmd(self, cmd):
        ''' Input:  binary cmd
            Output: return binary cmd as a string '''
        if isinstance(cmd, str):
            cmd = cmd.upper()
        try:
            cmd={1:'ON','1':'ON',0:'OFF','0':'OFF','ON':'ON','OFF':'OFF'}[cmd]
        except KeyError:
            print "Invalid operation: "+cmd
        else:
            return cmd

    def reset(self):
        ''' Input:  None
            Output: return nothing, but resets settings '''
        self.link.cmd("*RST")

    # *IDN? - Identification Query: Read identification code
    def identification(self):
        ''' Input:  None
            Output: return identification of instrument '''
        return self.link.ask("*IDN?")

    def self_test_query(self):
        ''' Input:  None
            Output: return test query '''
        return self.link.ask("*TST?")

    def Check_Error(self):
        ''' Input:  None
            Output: return any existing error that is 
                    shown on lcd screen of instrument '''
        error_numb,error = self.link.ask("SYST:ERR?").split(',')
        print "checking for error"
        if (error_numb != "0") and (error_numb != "-420"):
            print "Error has occured: "+error_numb+", "+error
            return "Error has occured: "+error_numb+", "+error
        elif (error_numb == "-420" and error != '"Query UNTERMINATED"'):
            print "Error has occured: "+error_numb+", "+error
            return "Error has occured: "+error_numb+", "+error

    #Channels 1 and 2
    @property
    def channel(self):
        ''' Input:  None
            Output: return channel number '''
        #print self.chan  # Uncomment for debug
        #self.chan=1
        return str(self.chan)

    @channel.setter
    def channel(self,chan):
        ''' Input: channel number
            Output: return nothing, but sets channel number '''
        valid_channels=[1,2]
        try:
            chan = int(chan)
            self.chan = str(valid_channels[valid_channels.index(chan)])
        except ValueError:
            print "Invalid Channel Number: "+str(chan)

    @property
    def output(self):
        ''' Input:  None
            Output: return 0 (OFF) or 1 (ON) for OUTPUT '''
        cmd = self.link.ask(":OUTPut"+self.chan+"?")
        if 'ON' in cmd:
            return 1
        else:
            return 0

    @output.setter
    def output (self, cmd):
        ''' Input:  0, OFF, 1, ON
            Output: return nothing, but sets output to be ON or OFF '''
        self.link.cmd(":OUTPut"+self.chan+" " + self._binary_cmd(cmd))

    @property
    def voltage_unit(self):
        ''' Input:  None
            Output: return units for voltage '''
        return self.link.ask(":VOLTage:UNIT?")

    @voltage_unit.setter
    def voltage_unit(self, unit):
        ''' Input:  unit (VPP, VRMS or DBM)
            Output: return nothing, but sets units for voltage  '''
        valid_set = {'VPP','VRMS','DBM'}
        unit = unit.upper()
        if unit not in valid_set:
            raise ValueError("Invalid units for voltage")
        else:
            self.link.cmd(":VOLTage:UNIT "+unit)
        
    @property 
    def amplitude (self):
        ''' Input:  None
            Output: return the amplitude of the waveform    ''' 
        return float( self.link.ask(":SOURce"+self.chan+":VOLTage:LEVel:IMMediate:AMPLitude?"))
    
    @amplitude.setter
    def amplitude (self, cmd):
        ''' Input:  Amplitude
            Output: return nothing, but sets amplitude of the waveform    '''
        self.link.cmd(":SOURce"+self.chan+":VOLTage:LEVel:IMMediate:AMPLitude " +
                      format( float(cmd),'E'))

    @property
    def frequency (self):
        ''' Input:  None
            Output: return Frequency of the waveform    '''
        return float( self.link.ask(":SOURce"+self.chan+":FREQuency:FIXed?"))

    @frequency.setter
    def frequency (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd(":SOURce"+self.chan+":FREQuency:FIXed " + format( float(cmd), 'E'))

    @property
    def burst (self):
        ''' Input:  None
            Output: return Burst of the waveform    '''
        return self.link.ask(":SOURce"+self.chan+":BURST?")

    @burst.setter
    def burst (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd(":SOURce"+self.chan+":BURST:STATE "+cmd)   
 
    @property
    def burst_delay (self):
        ''' Input:  None
            Output: return Burst of the waveform    '''
        return self.link.ask(":SOURce"+self.chan+":BURST:TDELAY?")

    @burst_delay.setter
    def burst_delay (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd("SOURce"+self.chan+":BURST:TDELAY "+ str(cmd)+"us")
	#self.link.cmd("TRIG:SEQ:SOURCE TIM")
	#self.link.cmd(":TRIG:SEQ:TIM "+str(cmd) + "ms") 

    @property
    def burst_mode (self):
        ''' Input:  None
            Output: return Burst of the waveform    '''
        return self.link.ask(":SOURce"+self.chan+":BURST:MODE?")

    @burst_mode.setter
    def burst_mode (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd(":SOURce"+self.chan+":BURST:MODE "+str(cmd))
        valid_set = {'TRIG', 'GATE', 'INF'}
        cmd = cmd.upper()
        if cmd not in valid_set:
            raise ValueError("Invalid Function Type")
        else:
            self.link.cmd(":SOURce"+self.chan+":BURST:MODE "+str(cmd))

    @property
    def burst_trigger (self):
        ''' Input:  None
            Output: return Burst of the waveform    '''
        return self.link.ask(":SOURce"+self.chan+":BURST:TRIGger:SOURce?")

    @burst_trigger.setter
    def burst_trigger (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd(":SOURce"+self.chan+":BURST:MODE "+str(cmd))
        valid_set = {'INT', 'EXT', 'MAN'}
        cmd = cmd.upper()
        if cmd not in valid_set:
            raise ValueError("Invalid Function Type")
        else:
            self.link.cmd(":SOURce"+self.chan+":BURST:TRIGger:SOURce "+str(cmd))

    @property
    def burst_cycles (self):
        ''' Input:  None
            Output: return Burst of the waveform    '''
        return self.link.ask(":SOURce"+self.chan+":BURST:NCYCLes?")

    @burst_cycles.setter
    def burst_cycles (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd(":SOURce"+self.chan+":BURST:NCYCLes "+ str(cmd))

    @property
    def burst_phase (self):
        ''' Input:  None
            Output: return Burst of the waveform    '''
        return self.link.ask(":SOURce"+self.chan+":BURST:PHASE?")
    
    @burst_phase.setter
    def burst_phase (self, cmd):
        ''' Input:  Frequency
            Output: return nothing, but sets Frequency of the waveform    '''
        self.link.cmd("DELAY:SOURce"+self.chan+":BURST:PHASE "+ str(cmd))


    @property
    def function(self):
        return self.link.ask("FUNCtion?")
    
    @function.setter
    def function(self, cmd):
        valid_set = {'SINUSOID','SQUARE','RAMP','PULSE','NOISE','DC','USER'}
        cmd = cmd.upper()
        if cmd not in valid_set:
            raise ValueError("Invalid Function Type")
        else:
            self.link.cmd("FUNCtion "+str(cmd))

    @property
    def offset(self):
        return float(self.link.ask("VOLTage:OFFSet?"))
    
    @offset.setter
    def offset(self, offset):
        self.link.cmd("VOLTage:OFFSet "+format(float(offset),'E'))

    @property
    def output_polarity(self):
        return self.link.ask("OUTPut:POLarity?")

    @output_polarity.setter
    def output_polarity(self, cmd):
        valid_set = {'NORMAL','INVERTED'}
        cmd = cmd.upper()
        if cmd not in valid_set:
            raise ValueError("Invalid polarity")
        else:
            self.link.cmd("OUTPut:POLarity "+str(cmd))

    @property
    def output_sync(self):
        return int(self.link.ask("OUTPut:SYNC?"))

    @output_sync.setter
    def output_sync(self, cmd):
        self.link.cmd("OUTPut:SYNC "+ self._binary_cmd(cmd))

    @property
    def output_load(self):
        return float(self.link.ask("OUTPut:LOAD?"))

    @output_load.setter
    def output_load(self, cmd):
        self.link.cmd("OUTPut:LOAD "+str(cmd))

    @property
    def pulse_width_mode(self):
        return self.link.ask("FUNCtion:PULSe:HOLD?")

    @pulse_width_mode.setter
    def pulse_width_mode(self, cmd):
        valid_set = {'WIDTH','DCYCLE'}
        cmd = cmd.upper()
        if cmd not in valid_set:
            raise ValueError("Invalid pulse width mode")
        else:
            self.link.cmd("FUNCtion:PULSe:HOLD "+str(cmd))

    @property
    def pulse_dcycle(self):
        if 'DCYC' == self.pulse_width_mode:
            return float(self.link.ask("FUNCtion:PULSe:DCYCle?"))
        else:
            return None

    @pulse_dcycle.setter
    def pulse_dcycle(self, cycle):
        if 'DCYC' == self.pulse_width_mode:
            self.link.cmd("FUNCtion:PULSe:DCYCle "+format(float(cycle),'E'))

    @property
    def pulse_width(self):
        return float(self.link.ask("FUNCtion:PULSe:WIDTh?"))

    @pulse_width.setter
    def pulse_width(self,width):
        if 'WIDT' == self.pulse_width_mode:
            self.link.cmd("FUNCtion:PULSe:WIDTh "+format(float(width),'E'))

    @property
    def pulse_edge(self):
        return float(self.link.ask("PULSe:TRANsition?"))

    @pulse_edge.setter
    def pulse_edge(self,edge_time):
        self.link.cmd("PULSe:TRANsition "+format(float(edge_time),'E'))


