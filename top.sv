
`include "rx_fifo.sv"
`include "rx_pkt_dec.sv"
`include "crd_cntl.sv"
module rx_top(
 input  cxs_clk,
 input cxs_rst_n,
 input           tx_valid,
  input           rx_pkt_valid, //input
    input  [511:0] rx_pkt_data,
     input           cxs_crd_gnt,
     input           cxs_rx_active_ack,
    input  cxs_deactive_hint,
   output logic [2:0] cxs_prcl_type,
     output logic         cxs_rx_active_req,
     output logic  cxs_valid,
  output  logic [255:0] cxs_data,
  output logic         rx_ready,
    output logic    pkt_receive_sts_vld,
  output logic [1:0]   pkt_receive_sts,
    output logic cxs_rx_crd_rtn,
    output logic cxs_last,
  output logic[13:0] cxs_cntl);
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
  

  logic cxs_rx_crd_rtn_r;
  
  rx_fifo rx_fifo_inst (
    .clk(cxs_clk),
    .reset_n(cxs_rst_n),
    .tx_valid(tx_valid),
    .rx_pkt_valid(rx_pkt_valid),
    .cxs_crd_gnt(cxs_crd_gnt),
    .cxs_rx_active_ack(cxs_rx_active_ack),
    .rx_pkt_data(rx_pkt_data),
    .rx_ready(rx_ready),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .fifo_out_valid(fifo_out_valid),
    .pkt_receive_sts(pkt_receive_sts),
    .pkt_receive_sts_vld(pkt_receive_sts_vld),
    .fifo_data_out(fifo_data_out) );
  
    
  rx_pkt_dec rx_pkt_dec_inst(
    .clk(cxs_clk),               
    . reset_n(cxs_rst_n),             
    .tx_valid(tx_valid),        
    .rx_ready(rx_ready),
    .fifo_empty(fifo_empty),
    .fifo_full(fifo_full),
    .fifo_out_valid(fifo_out_valid),  
    .fifo_data_out(fifo_data_out),     
    .cxs_rx_active_req(cxs_rx_active_req),
    .rx_pkt_dec_vld(rx_pkt_dec_vld),
    .depkt_rx_data_vld(depkt_rx_data_vld),
    .depkt_rx_data(depkt_rx_data),
    .cxs_last(cxs_last),
    .cxs_cntl(cxs_cntl),
    .cxs_prcl_type(cxs_prcl_type),
    .cxs_valid(cxs_valid),
    .cxs_data(cxs_data));
  
  credit_control u_credit_control (
    .clk                  (cxs_clk),
    .reset_n              (cxs_rst_n),
      .cxs_valid            (cxs_valid),
      .cxs_rx_active_req    (cxs_rx_active_req),
      .depkt_rx_data_vld    (depkt_rx_data_vld),
    .cxs_rx_crd_rtn       (cxs_rx_crd_rtn)
  );

  
  // always_ff @(posedge clk or negedge reset_n) 
   // if (!reset_n)  cxs_prcl_type <= 3'b0;
    //  else cxs_prcl_type <= pkt_data_rx_vld? fifo_data_out[51:49]:3'b0;

    endmodule
