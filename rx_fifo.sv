//rx fifo
module rx_fifo(
    input                clk,                     // system clock (1-bit)
    input                reset_n,                 // active low reset (1-bit)
    input                tx_valid,                // TX valid signal (1-bit)
    input                tx_header_err_vld,       // header error valid (1-bit)
    input                rx_pkt_valid,            // RX packet valid (1-bit)
    input                rx_cxs_crd_gnt,          // credit grant (1-bit)
    input                rx_cxs_active_ack,       // active acknowledge (1-bit)
    input                rx_err_vld,              // RX error valid (1-bit)
    input                reg_ack,                 // register acknowledge (1-bit)
    input                rx_cxs_active_req,       // active request (1-bit)
    input        [511:0] rx_pkt_data,             // packet data (512-bit)
    output logic         rx_ready,                // ready signal (1-bit)
    output logic         fifo_full,               // FIFO full flag (1-bit)
    output logic         fifo_empty,              // FIFO empty flag (1-bit)
    output logic         fifo_out_valid,          // output valid (1-bit)
    output logic         pkt_receive_sts_vld,     // status valid (1-bit)
    output logic         fifo_overflow,           // overflow flag (1-bit)
    output logic         fifo_underflow,          // underflow flag (1-bit)
    output logic         fifo_empty_vld,          // delayed empty flag (1-bit)
    output logic [1:0]   pkt_receive_sts,         // packet status (2-bit)
    output logic [511:0] fifo_data_out            // FIFO output data (512-bit)
);

logic fifo_wr_en;                                 // write enable
logic fifo_rd_en;                                 // read enable
logic flit_en;                                    // flit consume enable
logic flit_valid;                                 // flit valid
logic fifo_rd_en_cnd;
logic fifo_out_valid_cnd;
logic fifo_data_out_cnd;
logic rd_ptr_cnd;
logic reg_ack_vld;                                // synchronized reg_ack valid
logic [1:0] rx_cxs_active_ack_r;                  // registered active ack
logic [1:0] rx_cxs_crd_gnt_r;                     // registered credit grant
logic [1:0] rx_sync;                              // synchronizer for reg_ack
logic [4:0] credit_outstanding;                   // credit counter
logic [6:0] wr_ptr;                               // write pointer
logic [6:0] rd_ptr;                               // read pointer
logic [511:0] fifo_mem [127:0];                   // FIFO storage (128 entries)
assign flit_valid     = fifo_out_valid;           // flit valid follows output valid
assign flit_en        = fifo_out_valid;           // flit enable same as valid
assign fifo_overflow  = fifo_full  & fifo_wr_en;  // overflow condition
assign fifo_underflow = fifo_empty & fifo_rd_en;  // underflow condition

//==================================================
// FIFO EMPTY FLAG LOGIC
// Detects when FIFO is empty (wr_ptr == rd_ptr)
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_empty <= 1'b0;             
    else fifo_empty <= (wr_ptr == rd_ptr);        
//==================================================
// FIFO FULL FLAG LOGIC
// Detects full condition using pointer MSB/LSB comparison
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_full <= 1'b0;              
    else fifo_full <= (wr_ptr[6] != rd_ptr[6]) & 
                      (wr_ptr[5:0] == rd_ptr[5:0]); 
//==================================================
// DELAYED EMPTY FLAG LOGIC
// Registers fifo_empty to avoid timing glitches
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_empty_vld <= 1'b0;         
    else fifo_empty_vld <= fifo_empty;            
//==================================================
// FIFO WRITE ENABLE LOGIC
// Enables write when valid data, ready and not full
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_wr_en <= 1'b0;             
    else fifo_wr_en <= (rx_pkt_valid & rx_ready & (!fifo_full)); 
//==================================================
// FIFO MEMORY WRITE LOGIC
// Writes incoming packet data into FIFO memory
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_mem[wr_ptr] <= 512'h0;     
    else fifo_mem[wr_ptr] <= (rx_pkt_valid & (!fifo_full)) ? 
                             rx_pkt_data : fifo_mem[wr_ptr]; 
//==================================================
// WRITE POINTER UPDATE LOGIC
// Circular increment of write pointer
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) wr_ptr <= 7'h0;                 
    else wr_ptr <= (wr_ptr == 7'h7F) ? 7'h0 :
                   (rx_pkt_valid & rx_ready & (!fifo_full)) ? 
                   wr_ptr + 7'h1 : wr_ptr;        
				   
//==================================================
// READ ENABLE CONDITION LOGIC (COMBINATIONAL)
// Generates condition for FIFO read enable
//==================================================
assign fifo_rd_en_cnd = (rx_cxs_crd_gnt & rx_cxs_active_ack & rx_cxs_active_req &
                         ((!fifo_empty) | (!fifo_empty_vld)));
//==================================================
// FIFO READ ENABLE REGISTER LOGIC
// Registers read enable condition
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_rd_en <= 1'b0;             
    else fifo_rd_en <= fifo_rd_en_cnd; 
//==================================================
// READ POINTER CONDITION LOGIC (COMBINATIONAL)
// Determines when read pointer should increment
//==================================================
assign rd_ptr_cnd = (rx_cxs_crd_gnt & rx_cxs_active_ack & rx_cxs_active_req &
                    ((!fifo_empty) | (!fifo_empty_vld)));
//==================================================
// READ POINTER UPDATE LOGIC
// Circular increment of read pointer
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rd_ptr <= 7'h0;                 
    else rd_ptr <= (rd_ptr == 7'h7F) ? 7'h0 :
                   (rd_ptr_cnd) ? (rd_ptr + 7'h1) : rd_ptr;     
//==================================================
// OUTPUT VALID CONDITION LOGIC (COMBINATIONAL)
// Checks when FIFO output is valid
//==================================================
assign fifo_out_valid_cnd = (rx_cxs_crd_gnt & rx_cxs_active_ack & rx_cxs_active_req &
                            (wr_ptr != rd_ptr) & (!fifo_empty) & (!fifo_empty_vld));
//==================================================
// FIFO OUTPUT VALID REGISTER LOGIC
// Drives fifo_out_valid signal
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_out_valid <= 1'b0;         
    else fifo_out_valid <= fifo_out_valid_cnd;
//==================================================
// OUTPUT DATA CONDITION LOGIC (COMBINATIONAL)
// Controls when FIFO data should be read
//==================================================
assign fifo_data_out_cnd =(rx_cxs_crd_gnt & rx_cxs_active_ack & rx_cxs_active_req &
                          (wr_ptr != rd_ptr) & (!fifo_empty) & (!fifo_empty_vld));
//==================================================
// FIFO DATA OUTPUT LOGIC
// Outputs data from FIFO memory
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_data_out <= 512'h0;        
    else fifo_data_out <= fifo_data_out_cnd ?  fifo_mem[rd_ptr] : 512'h0; 
//==================================================
// PACKET STATUS GENERATION LOGIC
// Generates status based on error and valid conditions
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) {pkt_receive_sts_vld, pkt_receive_sts} <= 3'b000; 
    else {pkt_receive_sts_vld, pkt_receive_sts} <= 
        (!rx_err_vld & fifo_out_valid) ? {1'b1,2'b01} : 
        (rx_err_vld  & fifo_out_valid) ? {1'b1,2'b10} : 
                                        3'b000;
//==================================================
// CREDIT MANAGEMENT LOGIC
// Tracks outstanding credits (increment/decrement)
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) credit_outstanding <= 5'h0;     
    else if (flit_en) credit_outstanding <= credit_outstanding - 1'b1; 
    else if (rx_ready) credit_outstanding <= credit_outstanding + 1'b1; 
//==================================================
// RX READY SIGNAL LOGIC
// Controls when FIFO can accept new data
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_ready <= 1'b0;               
    else if (!tx_valid | fifo_full | (!reg_ack_vld)) rx_ready <= 1'b0; 
    else if (tx_valid & (!fifo_full) & reg_ack_vld) rx_ready <= 1'b1; 
//==================================================
// DOUBLE FLOP SYNCHRONIZER LOGIC
// Synchronizes reg_ack signal to clk domain
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_sync <= 2'b00;               
    else rx_sync <= {rx_sync[0], reg_ack};        
//==================================================
// SYNCHRONIZED ACK VALID LOGIC
// Generates stable reg_ack_vld signal
//==================================================
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) reg_ack_vld <= 1'b0;            
    else reg_ack_vld <= rx_sync[1]; 
endmodule	