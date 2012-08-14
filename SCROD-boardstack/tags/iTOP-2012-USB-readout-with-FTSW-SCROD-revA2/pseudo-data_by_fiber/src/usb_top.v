`timescale 1ns/1ps

module usb_top
(
 input IFCLK,
 input CTL0,
 input CTL1,
 input CTL2,
 inout[15:0] FDD,
 output PA0,
 output PA1,
 output PA2,
 output PA3,
 output PA4,
 output PA5,
 output PA6,
 input PA7,
 output RDY0,
 output RDY1,
 input WAKEUP,
 input CLKOUT,
 
 output USB_FIFO_CLK,
// output USB_CHIPSCOPE_CLK,
 input USB_FIFO_RST,
// input NEW_DATA_RST,
 output [31:0]COMMAND_RX_DATA_BUS,
 output COMMAND_RX_RD_EN,
 input [15:0]QEV_TX_DATA_BUS,
// input QEV_TX_WR_EN,
 output QEV_TX_RD_EN,
// output QEV_TX_FULL,
 input QEV_TX_EMPTY
 
// inout [35:0]CONTROL
 
);

wire rst_usb_clk;
wire rst;

wire usb_buffed_ifclk_in;
wire usb_locked_ifclk_in;
wire usb_ifclk_in_locked;
wire usb_flagA_in;
wire usb_flagB_in;
wire usb_flagC_in;
wire usb_flagD_in;

wire [15:0] usb_fd_out;
wire [15:0] usb_fd_in;
wire usb_sloe;
wire [1:0] usb_fifo_adr;
wire usb_pktend;
wire usb_slrd;
wire usb_slwr;
wire usb_wakeup_in;

wire[15:0] wr_cs_fifo_data;
wire wr_cs_fifo_full;
wire wr_cs_fifo_we;

wire[15:0] wr_data_fifo_data;
wire wr_data_fifo_full;
wire wr_data_fifo_we;

wire rd_data_fifo_empty;
wire[15:0] rd_data_fifo_data; 
wire rd_data_fifo_re;

reg rd_cs_fifo_empty_r;
wire rd_cs_fifo_empty;
wire rd_cs_fifo_empty_w;
wire[15:0] rd_cs_fifo_data; 
wire rd_cs_fifo_re;

wire rst_external;

wire fpga2usb_data_req;
wire fpga2usb_cs_req;

wire sl_cs_fifo_empty;
wire sl_data_fifo_empty;
wire sl_cs_fifo_full;
wire sl_data_fifo_full;

wire COMMAND_FIFO_RD_EN;
reg COMMAND_FIFO_RD_EN_r;
wire COMMAND_FIFO_EMPTY;

wire [31:0]internal_COMMAND_RX_DATA_BUS;
wire internal_QEV_TX_FULL;

wire [105:0]trigger_bus;

assign sl_cs_fifo_empty= usb_flagA_in; //connect to the empty flag of EP4
assign sl_data_fifo_empty= usb_flagB_in; //connect to the empty flag of EP2
assign sl_cs_fifo_full= usb_flagC_in; //connect to the full flag of EP8
assign sl_data_fifo_full= usb_flagD_in; //connect to the full flag of EP6

assign USB_FIFO_CLK=usb_locked_ifclk_in;
//assign USB_CHIPSCOPE_CLK=usb_buffed_ifclk_in;

usb_slave_fifo_interface_io u_usb_slave_fifo_interface_io(
    .rst(rst_usb_clk), 
    .IFCLK(IFCLK), 
    .usb_buffed_ifclk_in(usb_buffed_ifclk_in), 
    .usb_locked_ifclk_in(usb_locked_ifclk_in), 
    .usb_ifclk_in_locked(usb_ifclk_in_locked), 
    .CTL0(CTL0), 
    .CTL1(CTL1), 
    .CTL2(CTL2), 
    .usb_flagA_in(usb_flagA_in), 
    .usb_flagB_in(usb_flagB_in), 
    .usb_flagC_in(usb_flagC_in), 
    .usb_flagD_in(usb_flagD_in),
    .FDD(FDD), 
    .usb_fd_out(usb_fd_out), 
    .usb_fd_in(usb_fd_in), 
    .PA2(PA2), 
    .usb_sloe(usb_sloe), 
    .PA4(PA4), 
    .PA5(PA5), 
    .usb_fifo_adr(usb_fifo_adr), 
    .PA6(PA6), 
    .usb_pktend(usb_pktend), 
    .RDY0(RDY0), 
    .usb_slrd(usb_slrd), 
    .RDY1(RDY1), 
    .usb_slwr(usb_slwr), 
    .WAKEUP(WAKEUP), 
    .usb_wakeup_in(usb_wakeup_in), 
    .PA0(PA0), 
    .PA1(PA1), 
    .PA3(PA3), 
    .PA7(PA7), 
    .CLKOUT(CLKOUT)
    );

usb_slave_fifo_interface u_usb_slave_fifo_interface (
    .clk(usb_locked_ifclk_in), 
    .rst(rst), 

    .fpga2usb_data_req(1'b1), 
    .fpga2usb_cs_req(1'b1), 

    .sl_data_fifo_empty(sl_data_fifo_empty), 
    .sl_cs_fifo_empty(sl_cs_fifo_empty),

    .sl_rd(usb_slrd), 
    .sl_rd_data(usb_fd_in), 

    .sl_data_fifo_full(sl_data_fifo_full), 
    .sl_cs_fifo_full(sl_cs_fifo_full),

    .sl_wr(usb_slwr), 
    .sl_wr_data(usb_fd_out), 
    .sl_pktend(usb_pktend), 
    .sl_fifo_adr(usb_fifo_adr), 
    .sl_oe(usb_sloe), 

    .wr_cs_fifo_data(wr_cs_fifo_data), 
    .wr_cs_fifo_full(wr_cs_fifo_full), 
    .wr_cs_fifo_we(wr_cs_fifo_we), 

    .wr_data_fifo_data(wr_data_fifo_data), 
    .wr_data_fifo_full(wr_data_fifo_full), 
    .wr_data_fifo_we(wr_data_fifo_we), 

    .rd_data_fifo_empty(rd_data_fifo_empty), 
    .rd_data_fifo_data(rd_data_fifo_data), 
    .rd_data_fifo_re(rd_data_fifo_re), 

    .rd_cs_fifo_empty(rd_cs_fifo_empty), 
    .rd_cs_fifo_data(rd_cs_fifo_data), 
    .rd_cs_fifo_re(rd_cs_fifo_re)
    );

usb_init u_init(
    .clk(usb_buffed_ifclk_in), 
    .wakeup(usb_wakeup_in),

    .usb_clk_lock(usb_ifclk_in_locked), 
    .usb_clk_rst(rst_usb_clk),

    .rst(USB_FIFO_RST), 
    .n_ready(rst)
    );

//////////////////Test FIFO//////////////////
test_usb_fifo u_test_usb_fifo_data (
  .clk(usb_locked_ifclk_in), // input clk
  .rst(rst), // input rst
  .din(wr_data_fifo_data), // input [15 : 0] din
  .wr_en(wr_data_fifo_we), // input wr_en
  .rd_en(rd_data_fifo_re), // input rd_en
  .dout(rd_data_fifo_data), // output [15 : 0] dout
  .full(wr_data_fifo_full), // output full
  .almost_full(), // output almost_full
  .empty(rd_data_fifo_empty), // output empty
  .almost_empty(), // output almost_empty
  .prog_full(), // output prog_full
  .prog_empty() // output prog_empty
);

////////////////Command FIFO////////////////
fifo_16_to_32_bit command_word_stitch(
	 .rst(USB_FIFO_RST),
    .wr_clk(usb_locked_ifclk_in),
    .rd_clk(usb_locked_ifclk_in),
    .din(wr_cs_fifo_data),
    .wr_en(wr_cs_fifo_we),
    .rd_en(COMMAND_FIFO_RD_EN),
    .dout({internal_COMMAND_RX_DATA_BUS[15:0],internal_COMMAND_RX_DATA_BUS[31:16]}),
    .full(),
    .empty(COMMAND_FIFO_EMPTY),
    .prog_full(wr_cs_fifo_full)
  );

	assign COMMAND_FIFO_RD_EN=(wr_cs_fifo_full || !COMMAND_FIFO_EMPTY);
	always@(posedge usb_locked_ifclk_in) begin
		COMMAND_FIFO_RD_EN_r <= COMMAND_FIFO_RD_EN;
	end
	assign COMMAND_RX_RD_EN=COMMAND_FIFO_RD_EN_r;
//////////////////////////////////////////////

///////////////////PACKET FIFO////////////////
//fifo_32_to_16_bit packet_word_split(
//	 .rst(USB_FIFO_RST/* || NEW_DATA_RST*/),
//    .wr_clk(usb_locked_ifclk_in),
//    .rd_clk(usb_locked_ifclk_in),
//    .din(QEV_TX_DATA_BUS),
//    .wr_en(QEV_TX_WR_EN),
//    .rd_en(rd_cs_fifo_re),
//    .dout(rd_cs_fifo_data),
//    .full(),
//    .empty(rd_cs_fifo_empty_w),
//    .prog_full(internal_QEV_TX_FULL)
//  );
//	always@(posedge usb_locked_ifclk_in) begin
//		if(rd_cs_fifo_empty_w)
//			rd_cs_fifo_empty_r <= 1'b1;
//		else if(internal_QEV_TX_FULL)
//			rd_cs_fifo_empty_r <= 1'b0;
//		else
//			rd_cs_fifo_empty_r <= rd_cs_fifo_empty_r;
//	end
//	assign rd_cs_fifo_empty = rd_cs_fifo_empty_r;
	assign rd_cs_fifo_data = QEV_TX_DATA_BUS;
	assign QEV_TX_RD_EN = rd_cs_fifo_re;
	assign rd_cs_fifo_empty = QEV_TX_EMPTY;
//////////////////////////////////////////////

assign COMMAND_RX_DATA_BUS = internal_COMMAND_RX_DATA_BUS;
//assign QEV_TX_FULL = internal_QEV_TX_FULL;

assign trigger_bus[31:0]=internal_COMMAND_RX_DATA_BUS;
assign trigger_bus[47:32]=wr_cs_fifo_data;
assign trigger_bus[63:48]=rd_cs_fifo_data;
assign trigger_bus[95:80]=QEV_TX_DATA_BUS;
assign trigger_bus[96]=wr_cs_fifo_we;
assign trigger_bus[97]=COMMAND_FIFO_RD_EN_r;
//assign trigger_bus[98]=QEV_TX_WR_EN;
assign trigger_bus[98]=QEV_TX_RD_EN;
assign trigger_bus[99]=rd_cs_fifo_re;
assign trigger_bus[100]=COMMAND_FIFO_EMPTY;
assign trigger_bus[101]=wr_cs_fifo_full;
assign trigger_bus[102]=rd_cs_fifo_empty;
assign trigger_bus[103]=QEV_TX_EMPTY;//internal_QEV_TX_FULL;
assign trigger_bus[104]=USB_FIFO_RST;
//assign trigger_bus[105]=NEW_DATA_RST;

//usb_ila CHIPSCOPE(
//    .CONTROL(CONTROL),
//    .CLK(usb_buffed_ifclk_in),
//    .TRIG0(trigger_bus)
//);

endmodule

