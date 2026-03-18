module credit_control (
    input         clk,
    input         reset_n,
    input       cxs_valid,
    input       cxs_rx_active_req,
    input       depkt_rx_data_vld,
    output logic        cxs_rx_crd_rtn
);

  logic [4:0] credit_cnt;
  logic       cxs_rx_crd_rtn_r;

always_ff @(posedge clk or negedge reset_n)
  if(!reset_n) credit_cnt <= 5'h0;
  else begin
    case ({cxs_valid, cxs_rx_crd_rtn_r})
      2'b10: credit_cnt <= credit_cnt + 1; // credit used
      2'b01: credit_cnt <= credit_cnt - 1; // credit returned
      2'b11: credit_cnt <= credit_cnt;     // no change
      default: credit_cnt <= credit_cnt;
    endcase
  end 
      always_comb
  cxs_rx_crd_rtn_r = (!cxs_rx_active_req & credit_cnt > 0);

 always_ff @(posedge clk or negedge reset_n)
   if(!reset_n) cxs_rx_crd_rtn <= 1'b0;
      else  cxs_rx_crd_rtn <=  (!depkt_rx_data_vld)? cxs_rx_crd_rtn_r : 1'b0;
endmodule
