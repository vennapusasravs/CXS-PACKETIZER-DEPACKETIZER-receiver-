// packet decoding
module rx_pkt_dec (
input        clk,               // system clock
input        reset_n,           // asynchronous active-low reset
input        tx_valid,          // transmitter valid signal
input        rx_ready,          // receiver ready signal
input        fifo_empty,        // FIFO empty flag
input        fifo_full,         // FIFO full flag
input        cxs_crd_gnt,       // credit grant from receiver
input        fifo_out_valid,    // FIFO output contains valid packet data
input  [511:0] fifo_data_out,   // 512-bit packet data from FIFO
output logic cxs_rx_active_req, // request signal to activate CXS RX link
output logic cxs_rx_crd_rtn,    // credit return signal
output logic [51:49] cxs_prcl_type, // protocol type field
output logic rx_pkt_dec_vld,    // packet decode valid
output logic cxs_valid,         // CXS valid signal
output logic cxs_last ,         // indicates last flit of packet
output logic [13:0] cxs_cntl,   // CXS control field
output logic depkt_rx_data_vld, // depacketized data valid
output logic [255:0] depkt_rx_data, // 256-bit payload data
output logic [255:0] cxs_data   // CXS data bus
);
logic cxs_last_rx_vld;           // valid flag for last field
logic cxs_cntl_rx_vld;           // valid flag for control field
logic cxs_last_rx;               // last flit indicator from packet
logic dp_rx_vld;                 // DP flag valid
logic dp_rx;                     // DP flag value
logic cp_rx_vld;                 // CP flag valid
logic cp_rx;                     // CP flag value
logic pkt_data_rx_vld;           // payload data valid
logic cxs_data_flitwidth_rx_vld; // flit width field valid
logic cxs_max_pkt_perflit_rx_vld;// packets per flit field valid
logic cxs_prcl_type_vld; 
logic cxs_rx_crd_rtn_r;        // protocol type valid
logic [4:0] credit_cnt;          // credit counter
logic [1:0] cxs_data_flitwidth_rx;   // flit width
logic [1:0] cxs_max_pkt_perflit_rx;  // maximum packets per flit
logic [13:0] cxs_cntl_rx;            // control field extracted from packet
logic [29:0] cxs_cntl_rsvd_rx_vld;   // reserved control bits check
logic [204:0] cxs_rsvd_rx_vld;       // reserved packet bits check
logic [255:0] pkt_data_rx;           // extracted packet payload
// extract control field from packet
assign {cxs_cntl_rx_vld,cxs_cntl_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[13:0]} : 15'h0;
// extract last flit indicator
assign {cxs_last_rx_vld,cxs_last_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[44]} : 2'h0;
// extract flit width configuration
assign {cxs_data_flitwidth_rx_vld,cxs_data_flitwidth_rx} =(fifo_out_valid) ? {1'b1,fifo_data_out[46:45]} : 3'h0;
// extract maximum packets per flit
assign {cxs_max_pkt_perflit_rx_vld,cxs_max_pkt_perflit_rx} =(fifo_out_valid) ? {1'b1,fifo_data_out[48:47]} : 3'h0;
// extract protocol type
assign {cxs_prcl_type_vld,cxs_prcl_type} = (fifo_out_valid) ? {1'b1,fifo_data_out[51:49]} : 4'h0;
// extract DP bit
assign {dp_rx_vld,dp_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[255]} : 2'h0;
// extract CP bit
assign {cp_rx_vld,cp_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[254]} : 2'h0;
// extract payload data
assign {pkt_data_rx_vld,pkt_data_rx} =(fifo_out_valid) ? {1'b1,fifo_data_out[511:256]} : 257'h0;
// check reserved control bits are zero
assign cxs_cntl_rsvd_rx_vld =  (fifo_out_valid & (fifo_data_out [43:14] == 30'h0));
// check reserved packet bits are zero
assign cxs_rsvd_rx_vld = (fifo_out_valid & (fifo_data_out [253:49] == 205'h0));
// packet decode valid when reserved fields are correct
assign rx_pkt_dec_vld =(cxs_cntl_rsvd_rx_vld & cxs_rsvd_rx_vld);
// credit counter logic
// increases when credit is used and decreases when credit returned
     always_ff @(posedge clk or negedge reset_n)
  if(!reset_n) credit_cnt <= 5'h0;
  else begin
    case ({cxs_valid, cxs_rx_crd_rtn_r})
      2'b10: credit_cnt <= credit_cnt + 1; // credit used
      2'b01: credit_cnt <= credit_cnt - 1; // credit returned
      2'b11: credit_cnt <= credit_cnt;     // no change
      default: credit_cnt <= credit_cnt;
    endcase
  end 
      always_comb
  cxs_rx_crd_rtn_r = (!cxs_rx_active_req & credit_cnt > 0);

 always_ff @(posedge clk or negedge reset_n)
   if(!reset_n) cxs_rx_crd_rtn <= 1'b0;
      else  cxs_rx_crd_rtn <=  (!depkt_rx_data_vld)? cxs_rx_crd_rtn_r : 1'b0;

always_ff @(posedge clk or negedge reset_n)
  if(!reset_n)  {depkt_rx_data_vld,depkt_rx_data} <= 257'h0;
  else {depkt_rx_data_vld,depkt_rx_data} <= pkt_data_rx_vld ? {1'b1,pkt_data_rx[255:0]} :257'h0;
// CXS active request logic
always_ff @(posedge clk or negedge reset_n)
  if(!reset_n) cxs_rx_active_req <= 1'b0;
  else if (fifo_empty) cxs_rx_active_req <=1'b0;
  else if (!fifo_empty) cxs_rx_active_req <= 1'b1;
  else cxs_rx_active_req <=1'b0;
// last flit output generation
always_ff @(posedge clk or negedge reset_n)
  if(!reset_n) cxs_last <= 1'b0;
  else cxs_last <= depkt_rx_data_vld ? cxs_last_rx : 1'b0;
// control field output generation
always_ff @(posedge clk or negedge reset_n)
  if(!reset_n)cxs_cntl <= 14'h0;
  else cxs_cntl <=  depkt_rx_data_vld ? cxs_cntl_rx : 14'h0;
// CXS valid signal generation
always_ff @(posedge clk or negedge reset_n)
  if (!reset_n)cxs_valid <= 1'b0;
  else cxs_valid <= depkt_rx_data_vld ? depkt_rx_data_vld :1'b0;
// CXS data output generation
always_ff @(posedge clk or negedge reset_n)
  if (!reset_n) cxs_data <= 256'h0;
  else  cxs_data <= depkt_rx_data_vld ? depkt_rx_data:256'h0;
endmodule


// error flags
// logic for credit return logic
