// --------------------------- Packet Decoding Module ---------------------------
module rx_pkt_dec (

    input        clk,                     // System clock
    input        reset_n,                 // Active-low asynchronous reset
    input        tx_valid,                // TX side valid indication
    input        rx_ready,                // RX ready signal
    input        fifo_empty,              // FIFO empty flag
    input        fifo_full,               // FIFO full flag
    input        rx_cxs_crd_gnt,          // Credit grant from downstream
    input        fifo_out_valid,          // FIFO output valid indicator
    input  [511:0] fifo_data_out,         // FIFO output data (512-bit)

    output logic rx_cxs_active_req,       // RX active request signal
    output logic [51:49] rx_cxs_prcl_type,// Protocol type extracted
    output logic rx_pkt_dec_vld,          // Packet decode valid flag
    output logic rx_cxs_valid,            // RX valid output
    output logic rx_cxs_last,             // Last flit indicator
    output logic [13:0] rx_cxs_cntl,      // Control field
    output logic depkt_rx_data_vld,       // Depacketized data valid
    output logic [255:0] depkt_rx_data,   // Depacketized payload
    output logic [255:0] rx_header,       // Reconstructed RX header
    output logic rx_header_err_vld,       // Header error flag
    output logic [255:0] rx_cxs_data      // Final RX output data
);
    // ---------------- Internal Signals ----------------
    logic cxs_last_rx_vld;                // Last field valid
    logic cxs_cntl_rx_vld;                // Control field valid
    logic cxs_last_rx;                    // Last field value
    logic dp_rx_vld;                      // DP bit valid
    logic dp_rx;                          // DP bit
    logic cp_rx_vld;                      // CP bit valid
    logic cp_rx;                          // CP bit
    logic pkt_data_rx_vld;                // Payload valid
    logic cxs_data_flitwidth_rx_vld;      // Flit width valid
    logic cxs_max_pkt_perflit_rx_vld;     // Max packet per flit valid
    logic rx_cxs_prcl_type_vld;           // Protocol type valid
    logic [1:0] cxs_data_flitwidth_rx;    // Flit width
    logic [1:0] cxs_max_pkt_perflit_rx;   // Max packets per flit
    logic [13:0] cxs_cntl_rx;             // Control field extracted
    logic [29:0] cxs_cntl_rsvd_rx_vld;    // Reserved control bits check
    logic [204:0] cxs_rsvd_rx_vld;        // Reserved bits check
    logic [255:0] pkt_data_rx;            // Extracted payload
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) {cxs_cntl_rx_vld, cxs_cntl_rx} <= 15'h0;     // Reset control
        else {cxs_cntl_rx_vld, cxs_cntl_rx} <= (fifo_out_valid) ? {1'b1, fifo_data_out[13:0]} : 15'h0;
    // ---------------- Header Field Extraction ----------------
    assign {cxs_last_rx_vld, cxs_last_rx} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[44]} : 2'h0; // Last bit
    assign {cxs_data_flitwidth_rx_vld, cxs_data_flitwidth_rx} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[46:45]} : 3'h0; // Flit width
    assign {cxs_max_pkt_perflit_rx_vld, cxs_max_pkt_perflit_rx} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[48:47]} : 3'h0; // Max pkt/flit
    assign {rx_cxs_prcl_type_vld, rx_cxs_prcl_type} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[51:49]} : 4'h0; // Protocol type
    assign {dp_rx_vld, dp_rx} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[255]} : 2'h0;   // DP bit
    assign {cp_rx_vld, cp_rx} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[254]} : 2'h0;   // CP bit
    // ---------------- Payload Extraction ----------------
    assign {pkt_data_rx_vld, pkt_data_rx} =
           (fifo_out_valid) ? {1'b1, fifo_data_out[511:256]} : 257'h0;
    // ---------------- Reserved Field Checks ----------------
    assign cxs_cntl_rsvd_rx_vld =
           (fifo_out_valid & (fifo_data_out[43:14] == 30'h0)); // Control reserved check
    assign cxs_rsvd_rx_vld =
           (fifo_out_valid & (fifo_data_out[253:49] == 205'h0)); // Header reserved check
    // Packet decode valid only if reserved bits are correct
    assign rx_pkt_dec_vld = (cxs_cntl_rsvd_rx_vld & cxs_rsvd_rx_vld);
    // ---------------- Depacketization ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n){depkt_rx_data_vld, depkt_rx_data} <= 257'h0;
        else {depkt_rx_data_vld, depkt_rx_data} <=  pkt_data_rx_vld ? {1'b1, pkt_data_rx} : 257'h0;
    // ---------------- Active Request ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) rx_cxs_active_req <= 1'b0;
        else if (fifo_empty) rx_cxs_active_req <= 1'b0;
        else rx_cxs_active_req <= 1'b1;
    // ---------------- Last Signal ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) rx_cxs_last <= 1'b0;
        else rx_cxs_last <= depkt_rx_data_vld ? cxs_last_rx : 1'b0;
    // ---------------- Control Output ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) rx_cxs_cntl <= 14'h0;
        else rx_cxs_cntl <= depkt_rx_data_vld ? cxs_cntl_rx : 14'h0;
    // ---------------- Valid Signal ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) rx_cxs_valid <= 1'b0;
        else rx_cxs_valid <= depkt_rx_data_vld;
    // ---------------- Data Output ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) rx_cxs_data <= 256'h0;
        else rx_cxs_data <= depkt_rx_data_vld ? depkt_rx_data : 256'h0;
    // ---------------- Header Error Check ----------------
    assign rx_header_err_vld =
        ((fifo_data_out[253:52] != 202'h0) |                    // Reserved bits
         (fifo_data_out[51:49] != rx_cxs_prcl_type) |           // Protocol mismatch
         (fifo_data_out[48:47] != 2'h1) |                       // Format mismatch
         (fifo_data_out[46:45] != 2'h1) |                       // Width mismatch
         (fifo_data_out[44]    != rx_cxs_last) |                // Last mismatch
         (fifo_data_out[43:14] != 30'h0) |                      // Reserved mismatch
         (fifo_data_out[13:0]  != rx_cxs_cntl));                // Control mismatch

    // ---------------- Header Reconstruction ----------------
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) rx_header <= 256'h0;
        else if (fifo_out_valid)
            rx_header <= {
                dp_rx,                     // [255] Data present
                cp_rx,                     // [254] Control present
                202'h0,                    // Reserved
                rx_cxs_prcl_type,          // Protocol type
                cxs_max_pkt_perflit_rx,    // Max packets per flit
                cxs_data_flitwidth_rx,     // Flit width
                cxs_last_rx,               // Last indicator
                30'h0,                     // Reserved
                cxs_cntl_rx                // Control field
            };
        else
            rx_header <= 256'h0;
endmodule