module rx_fifo # (
    parameter DATA_W = 512,
    parameter DEPTH  = 128
)(
    input  logic                 wr_clk,
    input  logic                 rd_clk,
    input  logic                 reset_n,

    input  logic                 tx_valid,
    input  logic                 rx_ready,

    input  logic                 rx_pkt_valid,
    input  logic [DATA_W-1:0]    rx_pkt_data,

    input  logic                 fifo_rd_en,
    output logic [DATA_W-1:0]    fifo_out_data,
    output logic                 fifo_out_valid,

    output logic [6:0]           wr_ptr,
    output logic [6:0]           rd_ptr,

    output logic                 fifo_empty,
    output logic                 fifo_full,
    output logic [1:0]           pkt_receive_sts
);

    logic [DATA_W-1:0] mem [0:DEPTH-1];
    logic fifo_wr_en;

    assign fifo_wr_en = rx_pkt_valid & rx_ready & tx_valid & !fifo_full;

    // WRITE LOGIC
  always_ff @(posedge wr_clk or negedge reset_n)
        if (!reset_n)
          mem[wr_ptr] <= 1'h0;
        else if (fifo_wr_en)
            mem[wr_ptr] <= rx_pkt_data;
  always_ff @(posedge wr_clk or negedge reset_n)
        if (!reset_n)
          wr_ptr <= 1'h0;
        else if (fifo_wr_en)
            begin
              if (wr_ptr == 7'h8)
                wr_ptr <= 7'h0;
            else
                wr_ptr <= wr_ptr + 7'h1;
           end
  
   // READ LOGIC
    // 1. Logic for fifo_out_valid
    always_ff @(posedge rd_clk or negedge reset_n)
      if (!reset_n) fifo_out_valid <= 1'h0;
        else if (fifo_rd_en & !fifo_empty) fifo_out_valid <= 1'b1;
        else   fifo_out_valid <= 1'h0;

  // 2. Logic for fifo_out_data
    always_ff @(posedge rd_clk or negedge reset_n)
      if (!reset_n) fifo_out_data <= 1'h0;
      else if (fifo_rd_en & !fifo_empty) fifo_out_data <= mem[rd_ptr];
       else fifo_out_data <= 1'h0;
    // 3. Logic for rd_ptr 
    always_ff @(posedge rd_clk or negedge reset_n)
        if (!reset_n)rd_ptr <= 7'h0;
        else if (fifo_rd_en & !fifo_empty)
            rd_ptr <= (rd_ptr == 7'h8) ? 7'h0 : (rd_ptr + 7'h1);

    // pkt_receive_sts
    always_ff @(posedge wr_clk or negedge reset_n) begin
        if (!reset_n)
            pkt_receive_sts <= 2'b00;
        else if (fifo_wr_en)
            pkt_receive_sts <= 2'b01;
        else if (rx_pkt_valid & !rx_ready)
            pkt_receive_sts <= 2'b10;
        else
            pkt_receive_sts <= 2'b00;
    end

    assign fifo_empty = (wr_ptr == rd_ptr);
                assign fifo_full  = ((wr_ptr + 1'h1) == rd_ptr) || (wr_ptr == 7'h8 & rd_ptr == 7'h0);
    
   endmodule
