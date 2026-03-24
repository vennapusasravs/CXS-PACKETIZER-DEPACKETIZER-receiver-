`timescale 1ns/1ps
module tb_rx_top;
logic rx_cxs_clk;
logic rx_cxs_rst_n;
logic tx_valid;
logic rx_pkt_valid;
logic [511:0] rx_pkt_data;
logic rx_cxs_crd_gnt;
//logic  pkt_data_rx_vld;
logic rx_cxs_active_ack;
logic rx_cxs_deactive_hint;
logic rx_cxs_active_req;
logic rx_cxs_valid;
logic [255:0] rx_cxs_data;
logic rx_ready;
logic pkt_receive_sts_vld;
logic [1:0] pkt_receive_sts;
logic rx_cxs_crd_rtn;
logic rx_cxs_last;
logic [2:0] rx_cxs_prcl_type;
  logic [13:0] rx_cxs_cntl;
//  logic  cxs_cntl_rsvd_rx_vld ;
//  logic   cxs_rsvd_rx_vld      ;
rx_top dut(
  .rx_cxs_clk(rx_cxs_clk),
  .rx_cxs_rst_n(rx_cxs_rst_n),
    .tx_valid(tx_valid),
    .rx_pkt_valid(rx_pkt_valid),
    .rx_pkt_data(rx_pkt_data),
    .rx_cxs_crd_gnt(rx_cxs_crd_gnt),
    .rx_cxs_active_ack(rx_cxs_active_ack),
    .rx_cxs_deactive_hint(rx_cxs_deactive_hint),
    .rx_cxs_active_req(rx_cxs_active_req),
    .rx_cxs_valid(rx_cxs_valid),
    .rx_cxs_data(rx_cxs_data),
    .rx_ready(rx_ready),
    .pkt_receive_sts_vld(pkt_receive_sts_vld),
    .pkt_receive_sts(pkt_receive_sts),
    .rx_cxs_crd_rtn(rx_cxs_crd_rtn),
    .rx_cxs_last(rx_cxs_last),
    .rx_cxs_prcl_type(rx_cxs_prcl_type),
  .rx_cxs_cntl(rx_cxs_cntl)
);


always #5 rx_cxs_clk = ~rx_cxs_clk;


initial begin
    rx_cxs_clk = 1'b0;
    rx_cxs_rst_n = 1'b0;
//  pkt_data_rx_vld = 0;
    tx_valid = 1'b0;
    rx_pkt_valid = 1'b0;
    rx_pkt_data = 512'h0;
    rx_cxs_crd_gnt = 1'b0;
    rx_cxs_active_ack= 1'b0;
  rx_cxs_deactive_hint = 1'b0; 
//    cxs_cntl_rsvd_rx_vld = 1'b0;
//     cxs_rsvd_rx_vld      = 1'b0;
 
  @(posedge rx_cxs_clk);
  @(posedge rx_cxs_clk);
  @(posedge rx_cxs_clk);
  @(posedge rx_cxs_clk);

   rx_cxs_rst_n = 1'b1;
  //   repeat(5) begin
  @(posedge rx_cxs_clk); 
    tx_valid = 1'b1;
    //rx_ready
//     repeat(10) @(posedge clk);
//     wait(cxs_rx_active_req);
//     cxs_crd_gnt = 1'b1;
//    @(posedge clk);
//     cxs_rx_active_ack = 1'b1;  
  
  @(posedge rx_cxs_clk);
  // wait(rx_ready);

  @(posedge rx_cxs_clk);
    wait(rx_ready);
    rx_pkt_valid = 1'b1;
    rx_pkt_data = 512'h8888_7777_6666_5555_5322_4242_2222_5555_6668_8888_7777_6666_5555_5322_4242_2222_5555_6668;
  //repeat(10) begin @(posedge clk); end

    #10;
  @(posedge rx_cxs_clk);
  wait(rx_cxs_active_req);
    rx_pkt_valid=1'b1;
   //wait(cxs_rx_active_req);
    rx_cxs_crd_gnt = 1'b1;
  @(posedge rx_cxs_clk);
    rx_cxs_active_ack = 1'b1;
  @(posedge rx_cxs_clk);
    rx_pkt_data = 512'h8888_8880_7777_6666_5555_1111_3333_4444_5566;
  @(posedge rx_cxs_clk);
    rx_pkt_data = 512'h10;
  @(posedge rx_cxs_clk);
    rx_pkt_data = 512'h100;

  @(posedge rx_cxs_clk);
    rx_pkt_valid = 1'b0;
    rx_pkt_data =512'h0;
    rx_cxs_deactive_hint = 1'b1; 
   // cxs_crd_gnt=1'b0;


//     cxs_cntl_rsvd_rx_vld = 0;
// cxs_rsvd_rx_vld      = 0;

  repeat(10) @(posedge rx_cxs_clk);
 #1000   $finish;
  end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_rx_top);
end

endmodule
 
