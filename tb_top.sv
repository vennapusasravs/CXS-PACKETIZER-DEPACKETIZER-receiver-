// Code your testbench here
// or browse Examples
`timescale 1ns/1ps
// --------------------------- TESTBENCH FOR RX_TOP ---------------------------
module tb_top_cxs_pktzr_depktzr_rx;
    // ---------------- CLOCK & RESET ----------------
    logic rx_cxs_clk;                 // System clock
    logic rx_cxs_rst_n;               // Active-low rese
    // ---------------- INPUT SIGNALS ----------------
    logic tx_valid;                   // TX valid
	logic reg_ack;
    logic rx_pkt_valid;               // Packet valid input
    logic [511:0] rx_pkt_data;        // Packet data input
    logic rx_cxs_crd_gnt;             // Credit grant
    logic rx_cxs_active_ack;          // Active acknowledge
    logic rx_cxs_deactive_hint;       // Deactivation hint
    // ---------------- OUTPUT SIGNALS ----------------
    logic rx_cxs_active_req;          // Active request
    logic rx_cxs_valid;               // Valid output
	logic reg_req;
    logic [255:0] rx_cxs_data;        // Output data
    logic rx_ready;                   // Ready signal
    logic pkt_receive_sts_vld;        // Status valid
    logic [1:0] pkt_receive_sts;      // Status
    logic rx_cxs_crd_rtn;             // Credit return
    logic rx_cxs_last;                // Last signal
    logic [2:0] rx_cxs_prcl_type;     // Protocol type
    logic [13:0] rx_cxs_cntl;         // Control field

    // ---------------- DUT INSTANTIATION ----------------
    top_cxs_pktzr_depktzr_rx dut (
        .rx_cxs_clk           (rx_cxs_clk),
        .rx_cxs_rst_n         (rx_cxs_rst_n),
        .tx_valid             (tx_valid),
		.reg_req              (req_req),
		.reg_ack              (reg_ack),
        .rx_pkt_valid         (rx_pkt_valid),
        .rx_pkt_data          (rx_pkt_data),
        .rx_cxs_crd_gnt       (rx_cxs_crd_gnt),
        .rx_cxs_active_ack    (rx_cxs_active_ack),
        .rx_cxs_deactive_hint (rx_cxs_deactive_hint),
        .rx_cxs_active_req    (rx_cxs_active_req),
        .rx_cxs_valid         (rx_cxs_valid),
        .rx_cxs_data          (rx_cxs_data),
        .rx_ready             (rx_ready),
        .pkt_receive_sts_vld  (pkt_receive_sts_vld),
        .pkt_receive_sts      (pkt_receive_sts),
        .rx_cxs_crd_rtn       (rx_cxs_crd_rtn),
        .rx_cxs_last          (rx_cxs_last),
        .rx_cxs_prcl_type     (rx_cxs_prcl_type),
        .rx_cxs_cntl          (rx_cxs_cntl)
    );

    // ---------------- CLOCK GENERATION ----------------
    always #0.5 rx_cxs_clk = ~rx_cxs_clk;   // 1GHz clock
    initial begin
        // ---------- INITIAL VALUES ----------
        rx_cxs_clk             = 1'b0;
        rx_cxs_rst_n           = 1'b0;
        tx_valid               = 1'b0;
		reg_ack                = 1'b0;
        rx_pkt_valid           = 1'b0;
        rx_pkt_data            = 512'h0;
        rx_cxs_crd_gnt         = 1'b0;
        rx_cxs_active_ack      = 1'b0;
        rx_cxs_deactive_hint   = 1'b0;
        // ---------- RESET SEQUENCE ----------
        @(posedge rx_cxs_clk);
        @(posedge rx_cxs_clk);
        @(posedge rx_cxs_clk);
        @(posedge rx_cxs_clk);
        rx_cxs_rst_n = 1'b1;   // Release reset
        // ---------- ENABLE TX ----------
        @(posedge rx_cxs_clk);
        tx_valid = 1'b1;
		@(posedge rx_cxs_clk);
		reg_ack  = 1'b1;
        // ---------- WAIT FOR READY ----------
        @(posedge rx_cxs_clk);
        @(posedge rx_cxs_clk);
		@(posedge rx_cxs_clk);
        wait(rx_ready);
        // ---------- SEND FIRST PACKET ----------
        rx_pkt_valid = 1'b1;
        rx_pkt_data  = 512'h8888_7777_6666_5555_5322_4242_2222_5555_6668_8888_7777_6666_5555_5322_4242_2222_5555_6668;
        #10;
        @(posedge rx_cxs_clk);
        wait(rx_cxs_active_req);
        rx_pkt_valid     = 1'b1;
        rx_cxs_crd_gnt   = 1'b1;
        @(posedge rx_cxs_clk);
        rx_cxs_active_ack = 1'b1;
        @(posedge rx_cxs_clk);
        rx_pkt_data = 512'h8888_8880_7777_6666_5555_1111_3333_4444_5566;
        @(posedge rx_cxs_clk);
        rx_pkt_data = 512'h10;
        @(posedge rx_cxs_clk);
        rx_pkt_data = 512'h100;
        @(posedge rx_cxs_clk);
        rx_pkt_valid         = 1'b0;
        rx_pkt_data          = 512'h0;
        rx_cxs_deactive_hint = 1'b1;
        repeat(10) @(posedge rx_cxs_clk);
        #1000 $finish;
    end
    // ---------------- WAVEFORM DUMP ----------------
    initial begin
        $dumpfile("dump.vcd");        // Output VCD file
        $dumpvars(0, tb_top_cxs_pktzr_depktzr_rx);      // Dump all signals
    end

endmodule