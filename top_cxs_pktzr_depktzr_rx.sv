module top_cxs_pktzr_depktzr_rx(
    input  rx_cxs_clk,                    // System clock
    input  rx_cxs_rst_n,                  // Active-low reset
    input  tx_valid,                      // TX valid input
    input  rx_pkt_valid,                  // Incoming packet valid
    input  rx_cxs_crd_gnt,                // Credit grant from downstream
    input  rx_cxs_active_ack,             // Active acknowledge
    input  rx_cxs_deactive_hint,          // Deactivation hint
	input 				reg_ack,
    input  [511:0] rx_pkt_data,           // Incoming packet data
	output logic reg_req,
    output logic rx_ready,                // Ready to accept data
    output logic pkt_receive_sts_vld,     // Packet status valid
    output logic rx_cxs_active_req,       // Request to activate link
    output logic rx_cxs_valid,            // Valid output
    output logic rx_cxs_last,             // Last flit indicator
    output logic rx_cxs_crd_rtn,          // Credit return
    output logic [1:0] pkt_receive_sts,   // Packet status
    output logic [2:0]  rx_cxs_prcl_type, // Protocol type
    output logic [13:0] rx_cxs_cntl,      // Control field
    output logic [255:0] rx_cxs_data      // Output data

);
    // ---------------- INTERNAL SIGNALS ----------------
    logic fifo_full;                   // FIFO full flag
    logic fifo_empty;                  // FIFO empty flag
    logic fifo_overflow;
    logic fifo_underflow;
	logic rx_err_vld;
	logic fifo_out_valid_en;
    logic fifo_out_valid;              // FIFO output valid
    logic [511:0] fifo_data_out;       // FIFO output data
    logic depkt_rx_data_vld;           // Depacketized data valid
    logic rx_pkt_dec_vld;              // Packet decode valid
    logic [255:0] depkt_rx_data;       // Depacketized data
    logic pkt_data_rx_vld;             // Internal payload valid
    logic [13:0] cxs_cntl_rx;          // Internal control field
    logic cxs_last_rx;                 // Internal last bit
    logic rx_cxs_crd_rtn_r;            // Registered credit return
    logic  fifo_empty_vld;

    // ---------------- FIFO INSTANCE (UNCHANGED) ----------------
    rx_fifo rx_fifo_inst (
        .clk                 (rx_cxs_clk),          // Clock
        .reset_n             (rx_cxs_rst_n),        // Reset
        .tx_valid            (tx_valid),            // TX valid
        .rx_pkt_valid        (rx_pkt_valid),        // Packet valid
        .rx_cxs_crd_gnt      (rx_cxs_crd_gnt),      // Credit grant
        .rx_cxs_active_ack   (rx_cxs_active_ack),   // Active acknowledge
        .rx_pkt_data         (rx_pkt_data),         // Packet data
        .rx_ready            (rx_ready),            // Ready output
        .fifo_full           (fifo_full),           // FIFO full
		.rx_err_vld          (rx_err_vld),
		.fifo_empty_vld      (fifo_empty_vld),
       .rx_cxs_active_req    (rx_cxs_active_req),
        .fifo_empty          (fifo_empty),          // FIFO empty
        .fifo_overflow       (fifo_overflow),       // FIFO overflow
        .fifo_underflow      (fifo_underflow),      // FIFO Underflow
        .fifo_out_valid      (fifo_out_valid),      // FIFO valid out
        .pkt_receive_sts     (pkt_receive_sts),     // Status
        .pkt_receive_sts_vld (pkt_receive_sts_vld), // Status valid
        .fifo_data_out       (fifo_data_out),       // FIFO data out
        .reg_ack 			 (reg_ack)				// Handshake acknowledgement from register block
    
    );

    // ---------------- PACKET DECODER (UNCHANGED) ----------------
    rx_pkt_dec rx_pkt_dec_inst (
        .clk                 (rx_cxs_clk),          // Clock
        .reset_n             (rx_cxs_rst_n),        // Reset
        .tx_valid            (tx_valid),            // TX valid
        .rx_ready            (rx_ready),            // Ready,
        .fifo_empty          (fifo_empty),          // FIFO empty
        .fifo_full           (fifo_full),           // FIFO full
        .fifo_out_valid      (fifo_out_valid),      // FIFO valid
        .fifo_underflow      (fifo_underflow),      // FIFO undeflow
        .fifo_overflow       (fifo_overflow),       // FIFO Overflow
        .fifo_data_out       (fifo_data_out),       // FIFO data
		.reg_req			 (reg_req),				// Handshake request signal to register block
        .rx_cxs_active_ack   (rx_cxs_active_ack),   // Active acknowledge
        .rx_cxs_active_req   (rx_cxs_active_req),   // Active request
        .rx_pkt_dec_vld      (rx_pkt_dec_vld),      // Decode valid
        .depkt_rx_data_vld   (depkt_rx_data_vld),   // Data valid
        .depkt_rx_data       (depkt_rx_data),       // Data
        .rx_cxs_last         (rx_cxs_last),         // Last
        .rx_cxs_cntl         (rx_cxs_cntl),         // Control
		.cxs_cntl_rx         (cxs_cntl_rx),
		.cxs_last_rx         (cxs_last_rx),
        .rx_cxs_prcl_type    (rx_cxs_prcl_type),    // Protocol
        .rx_cxs_valid        (rx_cxs_valid),        // Valid
        .rx_cxs_data         (rx_cxs_data),          // Data
		.rx_err_vld          (rx_err_vld),
		//Handshake
		.reg_ack				(reg_ack)
		
    );
    // ---------------- CREDIT CONTROL  ----------------
    rx_crd_cntl rx_crd_cntl_inst (
        .clk                 (rx_cxs_clk),          // Clock
        .reset_n             (rx_cxs_rst_n),        // Reset
        .rx_cxs_valid        (rx_cxs_valid),        // Valid
        .rx_cxs_active_req   (rx_cxs_active_req),   // Active req
        .depkt_rx_data_vld   (depkt_rx_data_vld),   // Data valid
        .rx_cxs_crd_rtn      (rx_cxs_crd_rtn)       // Credit return
    );

endmodule
