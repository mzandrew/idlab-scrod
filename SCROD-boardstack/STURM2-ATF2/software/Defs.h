#ifndef DEFS
#define DEFS

#define NUM_ASICS             1        // Number of ASIC chips
#define NUM_CHANNELS          9        // Number of channels
#define NUM_TOTAL_CHANNELS    NUM_ASICS*NUM_CHANNELS //  
#define NUM_SMPL              32       // samples per readout
#define NUM_PED_READS        10000     // Number of PED readouts
#define NUM_DAC               4096     // Number of DAC steps



#define BUFFERSIZE    300  //Size of buffer, need 5 more values due to headers and stuff.

#define DISABLE_SYNC_USB_MASK          0x00000001
#define ENABLE_SYNC_USB_MASK           0x00010001
#define SOFT_TRIG_MASK                 0x00000002
#define PEDSCAN_MASK                   0x00000003
#define DISABLE_PED_MASK               0x00000004
#define ENABLE_PED_MASK                0x00010004
#define DISABLE_VCAL_MASK              0x00000005
#define ENABLE_VCAL_MASK               0x00010005
#define DEBUG_MASK                     0x000000ff


#endif
