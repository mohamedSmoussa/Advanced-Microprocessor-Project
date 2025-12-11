module mem_wb_register (
    input  clk,
    input  rst,
    input  flush,  
    input  mem_reg_write,
    input  [7:0]  mem_result,  
    input  [1:0]  mem_reg_dist,
    input  [2:0]  wb_result_mux_mem ,    
    output reg wb_reg_write,
    output reg [7:0] wb_result,
    output reg [1:0]  wb_reg_dist,
    output reg [2:0]  wb_result_mux
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        wb_reg_write <= 0;
        wb_result <= 8'b0;
        wb_reg_dist<=0;
        wb_result_mux<=0;
    end 
    else if (flush) begin
        wb_reg_write <= 0;
        wb_result <= 8'b0;
        wb_reg_dist<=0;
        wb_result_mux<=0;
    end 
    else begin
        wb_reg_write <= mem_reg_write;
        wb_result  <= mem_result;
        wb_reg_dist<=mem_reg_dist;
        wb_result_mux<=wb_result_mux_mem;
    end
end
endmodule
