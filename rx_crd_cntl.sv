module rx_crd_cntl (

    input        clk,                    // 1-bit clock input                 
    input        reset_n,                // 1-bit active low reset           
    input        rx_cxs_valid,           // 1-bit valid input                
    input        rx_cxs_active_req,      // 1-bit active request             
    input        depkt_rx_data_vld,      // 1-bit depacket valid             
    output logic rx_cxs_crd_rtn          // 1-bit credit return              
);

logic [4:0] credit_cnt;                 // 5-bit credit counter             
logic       rx_cxs_crd_rtn_r;           // 1-bit internal credit return     
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) credit_cnt <= 5'h0;   // reset credit counter             
    else begin
        case ({rx_cxs_valid, rx_cxs_crd_rtn_r})
            2'b10: credit_cnt <= credit_cnt + 1; // increment credit         
            2'b01: credit_cnt <= credit_cnt - 1; // decrement credit         
            2'b11: credit_cnt <= credit_cnt;     // hold value               
            default: credit_cnt <= credit_cnt;   // default hold             
        endcase
    end 
always_comb
    rx_cxs_crd_rtn_r = (!rx_cxs_active_req & (credit_cnt > 0)); // generate credit return
always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) rx_cxs_crd_rtn <= 1'b0; // reset output                    
    else rx_cxs_crd_rtn <= (!depkt_rx_data_vld) ? rx_cxs_crd_rtn_r : 1'b0; // output logic
endmodule