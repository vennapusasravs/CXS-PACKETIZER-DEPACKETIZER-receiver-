`timescale 1ns/1ps
module tb_rx_top;
logic cxs_clk;
logic cxs_rst_n;
logic tx_valid;
logic rx_pkt_valid;
logic [511:0] rx_pkt_data;
logic cxs_crd_gnt;
//logic  pkt_data_rx_vld;
logic cxs_rx_active_ack;
logic cxs_deactive_hint;
logic cxs_rx_active_req;
logic cxs_valid;
logic [255:0] cxs_data;
logic rx_ready;
logic pkt_receive_sts_vld;
logic [1:0] pkt_receive_sts;
logic cxs_rx_crd_rtn;
logic cxs_last;
logic [2:0] cxs_prcl_type;
  logic [13:0] cxs_cntl;
//  logic  cxs_cntl_rsvd_rx_vld ;
//  logic   cxs_rsvd_rx_vld      ;
rx_top dut(
  .cxs_clk(cxs_clk),
  .cxs_rst_n(cxs_rst_n),
    .tx_valid(tx_valid),
    .rx_pkt_valid(rx_pkt_valid),
    .rx_pkt_data(rx_pkt_data),
    .cxs_crd_gnt(cxs_crd_gnt),
    .cxs_rx_active_ack(cxs_rx_active_ack),
    .cxs_deactive_hint(cxs_deactive_hint),
    .cxs_rx_active_req(cxs_rx_active_req),
    .cxs_valid(cxs_valid),
    .cxs_data(cxs_data),
    .rx_ready(rx_ready),
    .pkt_receive_sts_vld(pkt_receive_sts_vld),
    .pkt_receive_sts(pkt_receive_sts),
  .cxs_rx_crd_rtn(cxs_rx_crd_rtn),
    .cxs_last(cxs_last),
    .cxs_prcl_type(cxs_prcl_type),
  .cxs_cntl(cxs_cntl)
);


always #5 cxs_clk = ~cxs_clk;


initial begin
    cxs_clk = 1'b0;
    cxs_rst_n = 1'b0;
//  pkt_data_rx_vld = 0;
    tx_valid = 1'b0;
    rx_pkt_valid = 1'b0;
    rx_pkt_data = 512'h0;
    cxs_crd_gnt = 1'b0;
    cxs_rx_active_ack = 1'b0;
  cxs_deactive_hint = 1'b0; 
//    cxs_cntl_rsvd_rx_vld = 1'b0;
//     cxs_rsvd_rx_vld      = 1'b0;
 
  @(posedge cxs_clk);
  @(posedge cxs_clk);
  @(posedge cxs_clk);
  @(posedge cxs_clk);
  @(posedge cxs_clk);
   cxs_rst_n = 1'b1;
  //   repeat(5) begin
  @(posedge cxs_clk); 
    tx_valid = 1'b1;
    //rx_ready
//     repeat(10) @(posedge clk);
//     wait(cxs_rx_active_req);
//     cxs_crd_gnt = 1'b1;
//    @(posedge clk);
//     cxs_rx_active_ack = 1'b1;  
  
  @(posedge cxs_clk);
  // wait(rx_ready);

  @(posedge cxs_clk);
    wait(rx_ready);
    rx_pkt_valid = 1'b1;
    rx_pkt_data = 512'h8888_7777_6666_5555_5322_4242_2222_5555_6668_8888_7777_6666_5555_5322_4242_2222_5555_6668;
  //repeat(10) begin @(posedge clk); end

    #10;
  @(posedge cxs_clk);
  wait(cxs_rx_active_req);
    rx_pkt_valid=1'b1;
   //wait(cxs_rx_active_req);
    cxs_crd_gnt = 1'b1;
  @(posedge cxs_clk);
    cxs_rx_active_ack = 1'b1;
  @(posedge cxs_clk);
    rx_pkt_data = 512'h8888_8880_7777_6666_5555_1111_3333_4444_5566;
  @(posedge cxs_clk);
    rx_pkt_data = 512'h10;
  @(posedge cxs_clk);
    rx_pkt_data = 512'h100;

  @(posedge cxs_clk);
    rx_pkt_valid = 1'b0;
    rx_pkt_data =512'h0;
    cxs_deactive_hint = 1'b1; 
   // cxs_crd_gnt=1'b0;


//     cxs_cntl_rsvd_rx_vld = 0;
// cxs_rsvd_rx_vld      = 0;

  repeat(10) @(posedge cxs_clk);
 #1000   $finish;
  end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_rx_top);
end

endmodule
