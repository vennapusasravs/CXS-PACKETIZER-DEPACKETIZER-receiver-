
`include "rx_fifo.sv"
`include "rx_pkt_dec.sv"
`include "crd_cntl.sv"
module rx_top(
 input  rx_cxs_clk,
 input rx_cxs_rst_n,
 input           tx_valid,
  input           rx_pkt_valid, //input
    input  [511:0] rx_pkt_data,
     input           rx_cxs_crd_gnt,
     input           rx_cxs_active_ack,
    input  rx_cxs_deactive_hint,
   output logic [2:0] rx_cxs_prcl_type,
     output logic         rx_cxs_active_req,
     output logic  rx_cxs_valid,
  output  logic [255:0] rx_cxs_data,
  output logic         rx_ready,
    output logic    pkt_receive_sts_vld,
  output logic [1:0]   pkt_receive_sts,
    output logic rx_cxs_crd_rtn,
    output logic rx_cxs_last,
  output logic[13:0] rx_cxs_cntl);
logic fifo_full;
logic fifo_empty;
 logic [13:0] cxs_cntl_rx;
  logic cxs_last_rx;
logic fifo_out_valid;
  logic [511:0] fifo_data_out;
logic depkt_rx_data_vld;
  logic rx_pkt_dec_vld;
  logic [255:0] depkt_rx_data;
 logic pkt_data_rx_vld;
  

  logic rx_cxs_crd_rtn_r;
  
  rx_fifo rx_fifo_inst (
    .clk(rx_cxs_clk),
    .reset_n(rx_cxs_rst_n),
    .tx_valid(tx_valid),
    .rx_pkt_valid(rx_pkt_valid),
    .rx_cxs_crd_gnt(rx_cxs_crd_gnt),
    .rx_cxs_active_ack(rx_cxs_active_ack),
    .rx_pkt_data(rx_pkt_data),
    .rx_ready(rx_ready),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .fifo_out_valid(fifo_out_valid),
    .pkt_receive_sts(pkt_receive_sts),
    .pkt_receive_sts_vld(pkt_receive_sts_vld),
    .fifo_data_out(fifo_data_out) );
  
    
  rx_pkt_dec rx_pkt_dec_inst(
    .clk(rx_cxs_clk),               
    . reset_n(rx_cxs_rst_n),             
    .tx_valid(tx_valid),        
    .rx_ready(rx_ready),
    .fifo_empty(fifo_empty),
    .fifo_full(fifo_full),
    .fifo_out_valid(fifo_out_valid),  
    .fifo_data_out(fifo_data_out),     
    .rx_cxs_active_req(rx_cxs_active_req),
    .rx_pkt_dec_vld(rx_pkt_dec_vld),
    .depkt_rx_data_vld(depkt_rx_data_vld),
    .depkt_rx_data(depkt_rx_data),
    .rx_cxs_last(rx_cxs_last),
    .rx_cxs_cntl(rx_cxs_cntl),
    .rx_cxs_prcl_type(rx_cxs_prcl_type),
    .rx_cxs_valid(rx_cxs_valid),
    .rx_cxs_data(rx_cxs_data));
  
  credit_control u_credit_control (
    .clk                  (rx_cxs_clk),
    .reset_n              (rx_cxs_rst_n),
    .rx_cxs_valid            (rx_cxs_valid),
      .rx_cxs_active_req    (rx_cxs_active_req),
      .depkt_rx_data_vld    (depkt_rx_data_vld),
    .rx_cxs_crd_rtn       (rx_cxs_crd_rtn)
  );

  
  // always_ff @(posedge clk or negedge reset_n) 
   // if (!reset_n)  cxs_prcl_type <= 3'b0;
    //  else cxs_prcl_type <= pkt_data_rx_vld? fifo_data_out[51:49]:3'b0;

    endmodule
