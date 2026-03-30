// packet decoding
module rx_pkt_dec (

    input        clk,                    // 1-bit clock input                  
    input        reset_n,                // 1-bit active low reset            
    input        tx_valid,               // 1-bit tx valid signal             
    input        rx_ready,               // 1-bit ready from downstream       
    input        fifo_empty,             // 1-bit fifo empty flag             
    input        fifo_full,              // 1-bit fifo full flag              
    input        rx_cxs_crd_gnt,         // 1-bit credit grant                
    input        rx_cxs_active_ack,      // 1-bit active acknowledge          
    input        fifo_out_valid,         // 1-bit fifo data valid             
    input        fifo_overflow,          // 1-bit overflow flag               
    input        fifo_underflow,         // 1-bit underflow flag              
    input  [511:0] fifo_data_out,        // 512-bit fifo output data          
    output logic  reg_req,
    output logic        rx_cxs_active_req,   // 1-bit active request           
    output logic [2:0]  rx_cxs_prcl_type,    // 3-bit protocol type            
    output logic        rx_pkt_dec_vld,      // 1-bit decode valid             
    output logic        rx_cxs_valid,        // 1-bit output valid             
    output logic        rx_cxs_last,         // 1-bit last signal              
    output logic        rx_err_vld,          // 1-bit error valid              
    output logic [13:0] rx_cxs_cntl,         // 14-bit control field           
    output logic        depkt_rx_data_vld,   // 1-bit depacket valid           
    output logic [255:0] depkt_rx_data,      // 256-bit depacket data          
    output logic [255:0] rx_cxs_data,        // 256-bit output data            
    output logic [255:0] rx_header           // 256-bit header                 
);

parameter CXS_STOP      = 4'b0001;      // stop state                        
parameter CXS_ACTIVE    = 4'b0010;      // active state                      
parameter CXS_RUN       = 4'b0100;      // run state                         
parameter CXS_DEACTIVE  = 4'b1000;      // deactive state                    

logic [3:0] cxs_cur_state, cxs_next_state; // state registers               
logic cxs_last_rx_vld;                 // last valid                        
logic cxs_cntl_rx_vld;                 // control valid                     
logic cxs_last_rx;                     // last bit                          
logic dp_rx_vld;                       // dp valid                          
logic dp_rx;                           // dp bit                            
logic cp_rx_vld;                       // cp valid                          
logic cp_rx;                           // cp bit                            
logic pkt_data_rx_vld;                 // packet data valid                 
logic cxs_data_flitwidth_rx_vld;       // flit width valid                  
logic cxs_max_pkt_perflit_rx_vld;      // max pkt per flit valid            
logic rx_cxs_prcl_type_vld;            // protocol type valid               
logic [1:0] cxs_data_flitwidth_rx;     // flit width                        
logic [1:0] cxs_max_pkt_perflit_rx;    // max pkt per flit                  
logic [13:0] cxs_cntl_rx;              // control                           
logic [29:0] cxs_cntl_rsvd_rx_vld;     // reserved check                    
logic [204:0] cxs_rsvd_rx_vld;         // reserved check                    
logic [255:0] pkt_data_rx;             // packet data                       

assign {cxs_cntl_rx_vld,cxs_cntl_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[13:0]} : 15'h0;        // control extraction        
assign {cxs_last_rx_vld,cxs_last_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[44]} : 2'h0;            // last extraction           
assign {cxs_data_flitwidth_rx_vld,cxs_data_flitwidth_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[46:45]} : 3'h0; // flit width extraction
assign {cxs_max_pkt_perflit_rx_vld,cxs_max_pkt_perflit_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[48:47]} : 3'h0; // max pkt extraction
assign {rx_cxs_prcl_type_vld,rx_cxs_prcl_type} = (fifo_out_valid) ? {1'b1,fifo_data_out[51:49]} : 4'h0; // protocol extraction    
assign {dp_rx_vld,dp_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[255]} : 2'h0;                        // dp extraction           
assign {cp_rx_vld,cp_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[254]} : 2'h0;                        // cp extraction           
assign {pkt_data_rx_vld,pkt_data_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[511:256]} : 257'h0;      // data extraction         

assign cxs_cntl_rsvd_rx_vld = (fifo_out_valid & (fifo_data_out[43:14] == 30'h0));                      // reserved check          
assign cxs_rsvd_rx_vld      = (fifo_out_valid & (fifo_data_out[253:49] == 205'h0));                    // reserved check          
assign rx_pkt_dec_vld       = (cxs_cntl_rsvd_rx_vld & cxs_rsvd_rx_vld);                                 // decode valid            

 always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) reg_req <= 1'b0;        
    else          reg_req <= tx_valid;
	
always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) {depkt_rx_data_vld,depkt_rx_data} <= 257'h0;                                           // reset depacket         
    else {depkt_rx_data_vld,depkt_rx_data} <= pkt_data_rx_vld ? {1'b1,pkt_data_rx[255:0]} : 257'h0;     // update depacket        

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) rx_cxs_active_req <= 1'b0;                                                              // reset active req       
    else if (fifo_empty) rx_cxs_active_req <= 1'b0;                                                      // empty condition        
    else if (!fifo_empty) rx_cxs_active_req <= 1'b1;                                                     // active condition       
    else rx_cxs_active_req <= 1'b0;                                                                      // default               

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) rx_cxs_last <= 1'b0;                                                                    // reset last             
    else rx_cxs_last <= depkt_rx_data_vld ? cxs_last_rx : 1'b0;                                          // update last            

always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) rx_cxs_cntl <= 14'h0;                                                                   // reset control          
    else rx_cxs_cntl <= depkt_rx_data_vld ? cxs_cntl_rx : 14'h0;                                         // update control         

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_valid <= 1'b0;                                                                  // reset valid            
    else rx_cxs_valid <= depkt_rx_data_vld & (cxs_cur_state == CXS_RUN) ? depkt_rx_data_vld : 1'b0;      // valid logic            

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_data <= 256'h0;                                                                 // reset data             
    else rx_cxs_data <= depkt_rx_data_vld & (cxs_cur_state == CXS_RUN) ? depkt_rx_data : 256'h0;         // data output            

assign rx_err_vld =
        ((fifo_data_out[253:52] != 202'h0) |                                                             // reserved bits          
         (fifo_data_out[51:49] != rx_cxs_prcl_type) |                                                     // protocol mismatch      
         (fifo_data_out[48:47] != 2'h1) |                                                                 // format mismatch        
         (fifo_data_out[46:45] != 2'h1) |                                                                 // width mismatch         
         (fifo_data_out[44]    != rx_cxs_last) |                                                          // last mismatch          
         (fifo_data_out[43:14] != 30'h0) |                                                                // reserved mismatch      
         (fifo_data_out[13:0]  != rx_cxs_cntl) |                                                          // control mismatch       
         fifo_overflow | fifo_underflow);                                                                // fifo error             

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_header <= 256'h0;                                                                   // reset header           
    else if (fifo_out_valid)
        rx_header <= {
            dp_rx,                                                                                       // dp bit                
            cp_rx,                                                                                       // cp bit                
            202'h0,                                                                                      // reserved              
            rx_cxs_prcl_type,                                                                            // protocol              
            cxs_max_pkt_perflit_rx,                                                                      // max pkt               
            cxs_data_flitwidth_rx,                                                                       // flit width            
            cxs_last_rx,                                                                                 // last                  
            30'h0,                                                                                       // reserved              
            cxs_cntl_rx                                                                                  // control               
        };
    else rx_header <= 256'h0;                                                                            // default               

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) cxs_cur_state <= CXS_STOP;                                                             // reset state           
    else cxs_cur_state <= cxs_next_state;                                                                // update state          

always_comb begin
    cxs_next_state = cxs_cur_state;                                                                      // default hold          

    case(cxs_cur_state)

        CXS_STOP:
            cxs_next_state = (rx_cxs_active_req & !rx_cxs_active_ack) ? CXS_ACTIVE : CXS_STOP;           // stop->active          

        CXS_ACTIVE:
            cxs_next_state = (rx_cxs_active_req & rx_cxs_active_ack) ? CXS_RUN : CXS_ACTIVE;             // active->run           

        CXS_RUN:
            cxs_next_state = (!rx_cxs_active_req & rx_cxs_active_ack) ? CXS_DEACTIVE : CXS_RUN;          // run->deactive         

        CXS_DEACTIVE:
            cxs_next_state = (!rx_cxs_active_req & !rx_cxs_active_ack) ? CXS_STOP : CXS_DEACTIVE;        // deactive->stop        

        default:
            cxs_next_state = CXS_STOP;                                                                   // default state         

    endcase
end

endmodule