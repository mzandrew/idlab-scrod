#ifndef IRS3B_REGISTERS__H
#define IRS3B_REGISTERS__H

unsigned int ROW02_GPIO0_ADDR = 0x78;
unsigned int ROW02_GPIO1_ADDR = 0x7A;
unsigned int ROW02_GPIO2_ADDR = 0x7C;
unsigned int ROW13_GPIO0_ADDR = 0x70;
unsigned int ROW13_GPIO1_ADDR = 0x72;
//unsigned int ROW13_GPIO2_ADDR = 0x74; //RevC
unsigned int ROW13_GPIO2_ADDR = 0x7E; //intermediate - RevD
unsigned int interconnect_revC_GPIO0_ADDR = 0x40;
unsigned int interconnect_revC_GPIO1_ADDR = 0x42;

#define LEDS    0
#define I2C_BUS_0_WR    1
#define I2C_BUS_1_WR    2
#define I2C_BUS_2_WR    3
#define TRG_INTF      4
#define TRGBIAS       5
#define TRGBIAS2      6
#define TRGTHREF      7
#define ISEL          8
#define SBBIAS        9
#define PUBIAS        10
#define CMPBIAS       11
#define DAC_BUF_BIASES    12

// registers 13-140 are Trigger thresholds
#define TRG_THRESH_base    13

#define WILK_RATE_FEEDBK_ENA  141
#define SAMP_RATE_FEEDBK_ENA  142
#define TRIG_WIDTH_FEEDBACK_ENA  143
//WILK_MON_CNTR_AUX  144

// registers 145-160 are Wilkinson rate counter target values
//WILK_RATE_CTR_TARGET_base  145

#define CMPBIAS2       155

#define FIRST_ALLOWED_WINDOW  161
#define LAST_ALLOWED_WINDOW  162
#define MAX_NUM_WINDOWS  163
#define MIN_NUM_WINDOWS  164
#define SWTRIG_PED_FLAGS    165
#define SCROD_ID    166
#define SCROD_REV    167
#define EVTNUM_LOW    168
#define EVTNUM_HIGH    169
#define SET_EVTNUM    170

// registers 171-178 are force channel masks
#define FORCE_CHAN_MASK_base  171

// registers 179-186 are ignore channel masks
#define IGNORE_CHAN_MASK_base  179

#define ROI_ADJUST_WIN  187
#define NUM_WINPAIRS_SAMP  188

// registers 189-199 are reserved

#define DAC_BUF_BIAS_ISEL    200
#define DAC_BUF_BIAS_VADJP    201
#define DAC_BUF_BIAS_VADJN    202

// registers 203-218 are VBIAS values
#define VBIAS_base  203

// registers 219-234 are VBIAS2 values
#define VBIAS2_base  219

// registers 235-250 are WBIAS values
#define WBIAS_base  235

// registers 251-266 are VADJP values (for setting sampling rate)
#define VADJP_base  251

// registers 267-282 are VADJN values (for setting sampling rate)
#define VADJN_base  267

// registers 283-298 are VDLY values (for setting wilkinson rate)
#define VDLY_base  283

// registers 299-314 are TIMING_SSP values
#define TIMING_SSP_base  299

// registers 315-329 are TIMING_S1 values
#define TIMING_S1_base  315

// registers 331-346 are TIMING_S2 values
#define TIMING_S2_base  331

// registers 347-362 are TIMING_PHASE values
#define TIMING_PHASE_base  347

// registers 363-378 are TIMING_WR_STRB values
#define TIMING_WR_STRB_base  363

#define TIMING_REG  379
#define TIMING_SELECT  380

// target values for wilkinson rate feedback
#define WILKINSON_TARGET_base  384 
// target values for sampling rate feedback
#define RCO_TARGET_base  400

// Bit 0 of following register controls the disabling of the internal buffer
// bias, the external DAC disable and the value written to the internal
// VADJP/VADJN:
#define USE_EXTERNAL_DACS_FOR_SAMPLING_RATE_CONTROL  416

#define I2C_BUS_3_WR  500
#define I2C_BUS_4_WR  501
#define I2C_BUS_5_WR  502
#define I2C_BUS_6_WR  503
#define I2C_BUS_7_WR  504

//# Read-only #

#define I2C_BUS_0_RD    512
#define I2C_BUS_1_RD    513
#define I2C_BUS_2_RD    514
#define I2C_BUS_3_RD    515
#define I2C_BUS_4_RD    516
#define I2C_BUS_5_RD    517
#define I2C_BUS_6_RD    518
#define I2C_BUS_7_RD    519

//registers 520-527 are ASIC scaler registers
#define ASIC_SCALER_RD_base    520

//registers 528-543 are DAC update statuses
//DAC_UPDATE_STATUS_RD_base  528

//registers 528-543 are Wilkinson monitor counters
#define WILK_MON_CTR_RD_base  528

//registers 544-559 are feedback DAC values for VDLY
#define FEEDBK_VDLY_RD_base  544

//560-575 are counters that count proportionally to the sampling rate for each ASIC
#define RCO_COUNTER_RD_base  560

//registers 576-591 are feedback DAC values for VADJN
#define FEEDBK_VADJN_RD_base  576

//registers 592-607 are feedback DAC values for VADJP
#define FEEDBK_VADJP_RD_base  592

//registers 592-607 are feedback DAC values for WBIAS
//FEEDBK_WBIAS_RD_base  592

#define EVTNUM_LOW_RD  608
#define EVTNUM_HIGH_RD  609

#define PLL_SECONDS_LOCKED_RD  610

#define FIRMWARE_REVISION_RD  611

#define TRIGGER_WIDTH_COUNTER_base  612

#define WBIAS_FB_base  628

#define FTSW_SECONDS_LOCKED_RD  644

#endif
