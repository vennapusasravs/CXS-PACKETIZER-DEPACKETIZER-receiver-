// packet decoding
module rx_pkt_dec (
    input                clk,                    // system clock (1-bit)
    input                reset_n,                // active low reset (1-bit)
    input                tx_valid,               // tx valid signal (1-bit)
    input                rx_ready,               // downstream ready (1-bit)
    input                fifo_empty,             // fifo empty flag (1-bit)
    input                fifo_full,              // fifo full flag (1-bit)
    input                rx_cxs_active_ack,      // active acknowledge (1-bit)
    input                fifo_out_valid,         // fifo data valid (1-bit)
    input                fifo_overflow,          // overflow flag (1-bit)
    input                fifo_underflow,         // underflow flag (1-bit)
    input                reg_ack,                // register acknowledge (1-bit)
    input  [511:0]       fifo_data_out,          // fifo output data (512-bit)

    output logic         reg_req,                // handshake request
    output logic         rx_cxs_active_req,      // active request
    output logic         rx_pkt_dec_vld,         // decode valid
    output logic         rx_cxs_valid,           // output valid
    output logic         rx_cxs_last,            // last signal
    output logic         rx_err_vld,             // error valid
    output logic         cxs_last_rx,            // last extracted
    output logic         depkt_rx_data_vld,      // depacket valid
    output logic [2:0]   rx_cxs_prcl_type,       // protocol type (3-bit)
    output logic [13:0]  rx_cxs_cntl,            // control field (14-bit)
    output logic [13:0]  cxs_cntl_rx,            // extracted control
    output logic [255:0] depkt_rx_data,          // depacketized data
    output logic [255:0] rx_cxs_data,            // output data
    output logic [255:0] rx_header               // header output
);
parameter CXS_STOP      = 4'b0001;               // stop state
parameter CXS_ACTIVE    = 4'b0010;               // active state
parameter CXS_RUN       = 4'b0100;               // run state
parameter CXS_DEACTIVE  = 4'b1000;               // deactive state

logic cxs_last_rx_vld;                           // last valid
logic cxs_cntl_rx_vld;                           // control valid
logic dp_rx_vld;                                 // dp valid
logic dp_rx;                                     // dp bit
logic cp_rx_vld;                                 // cp valid
logic cp_rx;                                     // cp bit
logic pkt_data_rx_vld;                           // packet data valid
logic cxs_data_flitwidth_rx_vld;                 // flit width valid
logic cxs_max_pkt_perflit_rx_vld;                // max pkt per flit valid
logic rx_cxs_prcl_type_vld;                      // protocol valid
logic rx_err_vld_en;                             // registered error
logic rx_cxs_data_cnd;
logic [1:0] cxs_data_flitwidth_rx;               // flit width
logic [1:0] cxs_max_pkt_perflit_rx;              // max packet per flit
logic [1:0] cxs_last_rx_d;                       // delayed last
logic [3:0] cxs_cur_state, cxs_next_state;       // FSM states
logic [14:0] cxs_cntl_rx_d;                      // delayed control
logic [29:0] cxs_cntl_rsvd_rx_vld;               // reserved check
logic [204:0] cxs_rsvd_rx_vld;                   // reserved check
logic [255:0] pkt_data_rx;                       // packet data
logic [255:0] rx_cxs_data_d;                     // delayed data

//==================================================
// CONTROL PIPELINE REGISTER
// Stores control field along with valid bit (1-cycle delay)
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) cxs_cntl_rx_d <= 15'h0;        
    else cxs_cntl_rx_d <= {cxs_cntl_rx_vld, cxs_cntl_rx}; 


//==================================================
// LAST SIGNAL PIPELINE REGISTER
// Stores last bit along with valid bit
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) cxs_last_rx_d <= 2'h0;         
    else cxs_last_rx_d <= {cxs_last_rx_vld, cxs_last_rx}; 


//==================================================
// DATA PIPELINE REGISTER
// Stores payload data along with valid bit
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_data_d <= 257'h0;       
    else rx_cxs_data_d <= {pkt_data_rx_vld, pkt_data_rx}; 


//==================================================
// CONTROL FIELD EXTRACTION LOGIC
// Extracts control bits [13:0] from FIFO data
//==================================================
assign {cxs_cntl_rx_vld, cxs_cntl_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[13:0]} : 15'h0;


//==================================================
// LAST BIT EXTRACTION LOGIC
// Extracts last flag from FIFO data
//==================================================
assign {cxs_last_rx_vld, cxs_last_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[44]} : 2'h0;


//==================================================
// FLIT WIDTH EXTRACTION LOGIC
// Extracts flit width field
//==================================================
assign {cxs_data_flitwidth_rx_vld, cxs_data_flitwidth_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[46:45]} : 3'h0;


//==================================================
// MAX PACKET PER FLIT EXTRACTION LOGIC
// Extracts max packet per flit field
//==================================================
assign {cxs_max_pkt_perflit_rx_vld, cxs_max_pkt_perflit_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[48:47]} : 3'h0;


//==================================================
// PROTOCOL TYPE EXTRACTION LOGIC
// Extracts protocol type field
//==================================================
assign {rx_cxs_prcl_type_vld, rx_cxs_prcl_type} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[51:49]} : 4'h0;


//==================================================
// DP BIT EXTRACTION LOGIC
// Extracts DP (data present) bit
//==================================================
assign {dp_rx_vld, dp_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[255]} : 2'h0;


//==================================================
// CP BIT EXTRACTION LOGIC
// Extracts CP (control present) bit
//==================================================
assign {cp_rx_vld, cp_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[254]} : 2'h0;


//==================================================
// PAYLOAD DATA EXTRACTION LOGIC
// Extracts payload data [511:256]
//==================================================
assign {pkt_data_rx_vld, pkt_data_rx} =
       (fifo_out_valid) ? {1'b1, fifo_data_out[511:256]} : 257'h0;


//==================================================
// RESERVED FIELD CHECK (CONTROL)
// Verifies reserved control bits are zero
//==================================================
assign cxs_cntl_rsvd_rx_vld =
       (fifo_out_valid & (fifo_data_out[43:14] == 30'h0));


//==================================================
// RESERVED FIELD CHECK (HEADER)
// Verifies reserved header bits are zero
//==================================================
assign cxs_rsvd_rx_vld =
       (fifo_out_valid & (fifo_data_out[253:49] == 205'h0));


//==================================================
// PACKET DECODE VALID LOGIC
// Valid only if all reserved checks pass
//==================================================
assign rx_pkt_dec_vld =
       (cxs_cntl_rsvd_rx_vld & cxs_rsvd_rx_vld);


//==================================================
// DEPACKETIZED DATA OUTPUT LOGIC
// Generates payload data and valid signal
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) {depkt_rx_data_vld, depkt_rx_data} <= 257'h0;
    else {depkt_rx_data_vld, depkt_rx_data} <=
         pkt_data_rx_vld ? {1'b1, pkt_data_rx} : 257'h0;


//==================================================
// ACTIVE REQUEST GENERATION LOGIC
// Requests activation when FIFO is not empty
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_active_req <= 1'b0;
    else if (fifo_empty) rx_cxs_active_req <= 1'b0;
    else if (!fifo_empty & rx_ready) rx_cxs_active_req <= 1'b1;


//==================================================
// LAST SIGNAL OUTPUT LOGIC
// Drives rx_cxs_last based on depacketized data
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_last <= 1'b0;
    else rx_cxs_last <= depkt_rx_data_vld ? cxs_last_rx_d : 1'b0;


//==================================================
// CONTROL OUTPUT LOGIC
// Drives rx_cxs_cntl from extracted control
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_cntl <= 14'h0;
    else rx_cxs_cntl <= depkt_rx_data_vld ? cxs_cntl_rx_d[13:0] : 14'h0;


//==================================================
// VALID OUTPUT LOGIC
// Valid only in RUN state with valid data
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_valid <= 1'b0;
    else rx_cxs_valid <= (depkt_rx_data_vld & (cxs_cur_state == CXS_RUN));


//==================================================
// DATA OUTPUT CONDITION LOGIC
// Enables data output only in valid RUN condition
//==================================================
assign rx_cxs_data_cnd =  (depkt_rx_data_vld &
                          (cxs_cur_state == CXS_RUN) &
                          (!rx_err_vld_en));


//==================================================
// DATA OUTPUT REGISTER LOGIC
// Drives rx_cxs_data output
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_data <= 256'h0;
    else rx_cxs_data <= rx_cxs_data_cnd ? depkt_rx_data : 256'h0;
	

//==================================================
// ERROR DETECTION LOGIC
// Checks protocol, reserved bits, format, overflow/underflow
//==================================================
assign rx_err_vld = (fifo_out_valid) ?
    ((fifo_data_out[253:52] != 202'h0) |
     (fifo_data_out[51:49] != rx_cxs_prcl_type) |
     (fifo_data_out[48:47] != 2'h1) |
     (fifo_data_out[46:45] != 2'h1) |
     (fifo_data_out[44]    != 1'h1) |
     (fifo_data_out[43:14] != 30'h0) |
     (fifo_data_out[13:0]  != cxs_cntl_rx) |
     fifo_overflow | fifo_underflow) : 1'b0;


//==================================================
// ERROR REGISTER LOGIC
// Stores error signal for stable usage
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_err_vld_en <= 1'b0;
    else rx_err_vld_en <= rx_err_vld;


//==================================================
// HEADER RECONSTRUCTION LOGIC
// Builds header from extracted fields
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_header <= 256'h0;
    else if (fifo_out_valid)
        rx_header <= {
            dp_rx,
            cp_rx,
            202'h0,
            rx_cxs_prcl_type,
            cxs_max_pkt_perflit_rx,
            cxs_data_flitwidth_rx,
            cxs_last_rx,
            30'h0,
            cxs_cntl_rx
        };
    else rx_header <= 256'h0;


//==================================================
// FSM STATE REGISTER
// Updates current state
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) cxs_cur_state <= CXS_STOP;
    else cxs_cur_state <= cxs_next_state;


//==================================================
// FSM NEXT STATE LOGIC
// Controls STOP → ACTIVE → RUN → DEACTIVE transitions
//==================================================
always_comb begin
    cxs_next_state = cxs_cur_state;
    case (cxs_cur_state)
        CXS_STOP:
            cxs_next_state =
                (rx_cxs_active_req & !rx_cxs_active_ack) ?
                CXS_ACTIVE : CXS_STOP;

        CXS_ACTIVE:
            cxs_next_state =
                (rx_cxs_active_req & rx_cxs_active_ack) ?
                CXS_RUN : CXS_ACTIVE;

        CXS_RUN:
            cxs_next_state =
                (!rx_cxs_active_req & rx_cxs_active_ack) ?
                CXS_DEACTIVE : CXS_RUN;

        CXS_DEACTIVE:
            cxs_next_state =
                (!rx_cxs_active_req & !rx_cxs_active_ack) ?
                CXS_STOP : CXS_DEACTIVE;

        default:
            cxs_next_state = CXS_STOP;
    endcase
end


//==================================================
// HANDSHAKE REQUEST LOGIC
// Generates register request based on tx_valid
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) reg_req <= 1'b0;
    else if (!tx_valid) reg_req <= 1'b0;
    else if (tx_valid) reg_req <= 1'b1;

endmodule