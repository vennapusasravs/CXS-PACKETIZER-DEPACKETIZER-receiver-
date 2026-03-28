module rx_fifo(

    input                clk,                     // 1-bit system clock                
    input                reset_n,                 // 1-bit active low reset           
    input                tx_valid,                // 1-bit tx valid                   
    input                rx_pkt_valid,            // 1-bit packet valid               
    input                rx_cxs_crd_gnt,          // 1-bit credit grant               
    input                rx_cxs_active_ack,       // 1-bit active ack                 
    input        [511:0] rx_pkt_data,             // 512-bit packet data              
    output logic         rx_ready,                // 1-bit ready                      
    output logic         fifo_full,               // 1-bit fifo full                  
    output logic         fifo_empty,              // 1-bit fifo empty                 
    output logic         fifo_out_valid,          // 1-bit fifo output valid          
    output logic         pkt_receive_sts_vld,     // 1-bit status valid               
    output logic         fifo_overflow,           // 1-bit overflow flag              
    output logic         fifo_underflow,          // 1-bit underflow flag             
    output logic [1:0]   pkt_receive_sts,         // 2-bit status                     
    output logic [511:0] fifo_data_out            // 512-bit fifo output data         
);
logic fifo_wr_en;                                 // write enable                     
logic fifo_rd_en;                                 // read enable                      
logic flit_en;                                    // flit consume                     
logic flit_valid;                                 // flit valid                       
logic [1:0] rx_cxs_active_ack_r;                  // registered active ack            
logic [1:0] rx_cxs_crd_gnt_r;                     // registered credit grant          
logic [3:0] wr_ptr;                               // write pointer                    
logic [3:0] rd_ptr;                               // read pointer                     
logic [4:0] credit_outstanding;                   // credit tracking                  
logic [511:0] fifo_mem [0:8];                     // fifo memory                      
assign flit_valid = fifo_out_valid;               // flit valid assignment            
assign flit_en    = fifo_out_valid;               // flit enable                      
assign fifo_full  = ((wr_ptr + 1) == rd_ptr);     // fifo full condition              
assign fifo_empty = (wr_ptr == rd_ptr);           // fifo empty condition             
assign fifo_overflow  = fifo_full  & fifo_wr_en;  // overflow condition               
assign fifo_underflow = fifo_empty & fifo_rd_en;  // underflow condition              

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_wr_en <= 1'b0;             // reset write enable               
    else fifo_wr_en <= (rx_pkt_valid & rx_ready & (!fifo_full)); // write enable logic

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_active_ack_r <= 2'h0;    // reset active ack reg             
    else rx_cxs_active_ack_r <= {rx_cxs_active_ack_r[0], rx_cxs_active_ack}; // shift reg

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_crd_gnt_r <= 2'h0;       // reset credit reg                 
    else rx_cxs_crd_gnt_r <= {rx_cxs_crd_gnt_r[0], rx_cxs_crd_gnt}; // shift reg       

always @(*) begin
    if (!reset_n) fifo_rd_en = 1'b0;              // reset read enable                
    else if ((!fifo_empty) & rx_cxs_crd_gnt & rx_cxs_active_ack) fifo_rd_en = 1'b1; // read enable
    else if ((!rx_cxs_crd_gnt_r[1]) | (!rx_cxs_active_ack_r[1]) | fifo_empty) fifo_rd_en = 1'b0; // disable read
end

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) pkt_receive_sts_vld <= 1'b0;    // reset status valid               
    else pkt_receive_sts_vld <= (fifo_wr_en | (rx_pkt_valid & (!rx_ready))); // status valid logic

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) pkt_receive_sts <= 2'b00;       // reset status                    
    else if (fifo_wr_en) pkt_receive_sts <= 2'b01; // write success                   
    else if (rx_pkt_valid & (!rx_ready)) pkt_receive_sts <= 2'b10; // overflow attempt
    else pkt_receive_sts <= 2'b00;       

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) credit_outstanding <= 5'h0;     // reset credit                    
    else if (flit_en) credit_outstanding <= credit_outstanding - 1'b1; // consume credit
    else if (rx_ready) credit_outstanding <= credit_outstanding + 1'b1; // add credit    

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_ready <= 1'b0;               // reset ready                     
    else if (!tx_valid | fifo_full) rx_ready <= 1'b0; // not ready                   
    else if (tx_valid & (!fifo_full)) rx_ready <= 1'b1; // ready                     

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_mem[wr_ptr] <= 512'h0;     // reset memory                    
    else fifo_mem[wr_ptr] <= (rx_pkt_valid & rx_ready & (!fifo_full)) ? rx_pkt_data : fifo_mem[wr_ptr]; // write data

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) wr_ptr <= 4'h0;                 // reset write pointer             
    else wr_ptr <= (wr_ptr == 4'h8) ? 4'h0 : (rx_pkt_valid & rx_ready & (!fifo_full)) ? wr_ptr + 4'h1 : wr_ptr; // increment

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rd_ptr <= 4'h0;                 // reset read pointer              
    else rd_ptr <= (rd_ptr == 4'h8) ? 4'h0 : (fifo_rd_en) ? rd_ptr + 4'h1 : rd_ptr; // increment read  

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_out_valid <= 1'b0;         // reset output valid              
    else fifo_out_valid <= fifo_rd_en;            // output valid logic              

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) fifo_data_out <= 512'h0;        // reset output data               
    else fifo_data_out <= fifo_rd_en ? fifo_mem[rd_ptr] : 512'h0; // read data      

endmodule