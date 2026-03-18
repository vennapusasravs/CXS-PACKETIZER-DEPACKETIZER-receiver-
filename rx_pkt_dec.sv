// packet decoding
module rx_pkt_dec (
    input        clk,               // input clock
    input        reset_n,             // asynchronous active-low reset
    input         tx_valid,           // transmitter valid
    input        rx_ready,
    input        fifo_empty,
    input        fifo_full,
    input     cxs_crd_gnt,
    input        fifo_out_valid,    // fifo has valid data
    input  [511:0] fifo_data_out,     // fifo 512-bit data
    output logic cxs_rx_active_req,
    output  logic [51:49] cxs_prcl_type,
    output logic rx_pkt_dec_vld,
    output  logic cxs_valid,
    output logic cxs_last ,
    output logic [13:0] cxs_cntl,
    output logic depkt_rx_data_vld,
    output logic [255:0] depkt_rx_data,
    output logic [255:0] cxs_data);
    logic cxs_last_rx_vld;
    logic cxs_cntl_rx_vld;
    logic cxs_last_rx;
    logic dp_rx_vld;
    logic dp_rx;
    logic cp_rx_vld;
    logic cp_rx;
    logic pkt_data_rx_vld;
    logic cxs_data_flitwidth_rx_vld;
    logic cxs_max_pkt_perflit_rx_vld;
    logic cxs_prcl_type_vld;
    logic[1:0] cxs_data_flitwidth_rx;
    logic [1:0] cxs_max_pkt_perflit_rx;
    logic [13:0] cxs_cntl_rx;
    logic [29:0] cxs_cntl_rsvd_rx_vld;
    logic [204:0] cxs_rsvd_rx_vld;
    logic [255:0] pkt_data_rx;
   
 //parameter MAX_CREDIT = 5'd16;
 // parameter credit_cnt = 5'h17; logic for crd count
      assign {cxs_cntl_rx_vld,cxs_cntl_rx} =  (fifo_out_valid) ? {1'b1,fifo_data_out[13:0]} : 15'h0; 
    
      assign {cxs_last_rx_vld,cxs_last_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[44]} : 2'h0; 
      
      assign {cxs_data_flitwidth_rx_vld,cxs_data_flitwidth_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[46:45]} : 3'h0;
      
      assign {cxs_max_pkt_perflit_rx_vld,cxs_max_pkt_perflit_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[48:47]} : 3'h0;
      
      assign {cxs_prcl_type_vld,cxs_prcl_type} = (fifo_out_valid) ? {1'b1,fifo_data_out[51:49]} : 4'h0;
      
      assign {dp_rx_vld,dp_rx}     = (fifo_out_valid) ? {1'b1,fifo_data_out[255]} : 2'h0;
      
      assign {cp_rx_vld,cp_rx}     = (fifo_out_valid) ? {1'b1,fifo_data_out[254]} : 2'h0;
      
      assign {pkt_data_rx_vld,pkt_data_rx} = (fifo_out_valid) ? {1'b1,fifo_data_out[511:256]} : 257'h0;
      
      assign cxs_cntl_rsvd_rx_vld = (fifo_out_valid & (fifo_data_out [43:14] == 30'h0)) ;
      assign cxs_rsvd_rx_vld = (fifo_out_valid & (fifo_data_out [253:49] == 205'h0)) ;
      
      assign rx_pkt_dec_vld =(cxs_cntl_rsvd_rx_vld & cxs_rsvd_rx_vld);

     
  always_ff @(posedge clk or negedge reset_n)
    if(!reset_n) {depkt_rx_data_vld,depkt_rx_data} <= 257'h0;
      else  {depkt_rx_data_vld,depkt_rx_data}	 <= pkt_data_rx_vld ? {1'b1,pkt_data_rx[255:0]} :257'h0	;

      always_ff @(posedge clk or negedge reset_n)
      if(!reset_n) cxs_rx_active_req <= 1'b0;
      else if (fifo_empty) cxs_rx_active_req <=1'b0;
      else if (!fifo_empty)  cxs_rx_active_req <= 1'b1;
   //  else if (fifo_empty & (!depkt_rx_data_vld)) cxs_rx_active_req <= 1'b0;
      else cxs_rx_active_req <=1'b0;
      
      always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) cxs_last <= 1'b0;
      else  cxs_last <= depkt_rx_data_vld ? cxs_last_rx : 1'b0;
      
      always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) cxs_cntl <= 14'h0;
      else  cxs_cntl <=  depkt_rx_data_vld ? cxs_cntl_rx : 14'h0; 
      
     always_ff @(posedge clk or negedge reset_n) 
    if (!reset_n)  cxs_valid <= 1'b0;
    else cxs_valid <= depkt_rx_data_vld? depkt_rx_data_vld:1'b0;
  
  always_ff @(posedge clk or negedge reset_n) 
    if (!reset_n)  cxs_data <= 256'h0;
      else   cxs_data <= depkt_rx_data_vld ? depkt_rx_data:256'h0;
      
        
endmodule




//error flags
//logic for credit return logic
