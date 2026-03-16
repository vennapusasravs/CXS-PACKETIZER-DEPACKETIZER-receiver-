// Include dependent modules
//`include "rx_fifo.sv"
//`include "rx_pkt_dec.sv"

//-------------------------------------------------------------
// Top module connecting FIFO and Packet Decoder
//-------------------------------------------------------------
module rx_top (
    input  cxs_clk,                     // system clock
    input  cxs_rst_n,                 // active-low reset
    input  tx_valid,                // transmitter valid signal
    input  rx_pkt_valid,            // packet valid from RX
    input  [511:0] rx_pkt_data,     // incoming 512-bit packet
    input  cxs_crd_gnt,             // credit grant from receiver
    input  cxs_rx_active_ack,       // link active acknowledge
    input  cxs_deactive_hint,       // link deactivation hint
    output logic [2:0]   cxs_prcl_type,     // protocol type
    output logic         cxs_rx_active_req, // request to activate RX link
    output logic         cxs_valid,         // CXS valid signal
    output logic [255:0] cxs_data,          // CXS data output
    output logic         rx_ready,          // RX ready status
    output logic         pkt_receive_sts_vld, // packet status valid
    output logic [1:0]   pkt_receive_sts,     // packet receive status
    output logic         cxs_rx_crd_rtn,      // credit return signal
    output logic         cxs_last,            // last flit indicator
    output logic [13:0]  cxs_cntl             // control field
);
    //---------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------
    logic         fifo_full;          // FIFO full flag
    logic         fifo_empty;         // FIFO empty flag
    logic         fifo_out_valid;     // FIFO output valid
    logic [511:0] fifo_data_out;      // data from FIFO
    logic         depkt_rx_data_vld;  // depacketized data valid
    logic         rx_pkt_dec_vld;     // packet decode valid
    logic [255:0] depkt_rx_data;      // depacketized data
    logic         pkt_data_rx_vld;    // packet data valid
    logic [13:0]  cxs_cntl_rx;        // control from decoder
    logic         cxs_last_rx;        // last flit from decoder
    //---------------------------------------------------------
    // FIFO Instance
    //---------------------------------------------------------
    rx_fifo rx_fifo_inst (
        .clk               (cxs_clk),
        .reset_n           (cxs_rst_n),
        .tx_valid          (tx_valid),
        .rx_pkt_valid      (rx_pkt_valid),
        .cxs_crd_gnt       (cxs_crd_gnt),
        .cxs_rx_active_ack (cxs_rx_active_ack),
        .rx_pkt_data       (rx_pkt_data),
        .rx_ready          (rx_ready),
        .fifo_full         (fifo_full),
        .fifo_empty        (fifo_empty),
        .fifo_out_valid    (fifo_out_valid),
        .pkt_receive_sts   (pkt_receive_sts),
        .fifo_data_out     (fifo_data_out)
    );
    //---------------------------------------------------------
    // Packet Decoder Instance
    //---------------------------------------------------------
    rx_pkt_dec rx_pkt_dec_inst(
        .clk               (cxs_clk),
        .reset_n           (cxs_rst_n),
        .tx_valid          (tx_valid),
        .rx_ready          (rx_ready),
        .fifo_empty        (fifo_empty),
        .fifo_full         (fifo_full),
        .fifo_out_valid    (fifo_out_valid),
        .fifo_data_out     (fifo_data_out),
        .cxs_rx_active_req (cxs_rx_active_req),
        .cxs_rx_crd_rtn    (cxs_rx_crd_rtn),
        .rx_pkt_dec_vld    (rx_pkt_dec_vld),
        .depkt_rx_data_vld (depkt_rx_data_vld),
        .depkt_rx_data     (depkt_rx_data),
        .cxs_last          (cxs_last),
        .cxs_cntl          (cxs_cntl)
    );

    //---------------------------------------------------------
    // Protocol Type Extraction
    //---------------------------------------------------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) cxs_prcl_type <= 3'b000;
        else cxs_prcl_type <= pkt_data_rx_vld ? fifo_data_out[51:49] : 3'b000;
endmodule
