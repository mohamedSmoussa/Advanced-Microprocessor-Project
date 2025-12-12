module ex_mem_register (
    input clk,
    input rst,
    input flush,  
    input ex_reg_write,
    input ex_mem_read,
    input ex_mem_write,
    input [7:0] ex_alu_result,
    input [7:0] ex_write_data,   
    input [1:0] ex_reg_dist,
    input [2:0] wb_result_mux_ex,
    input [1:0] mem_src_ex,
    input [1:0] stack_push_mux_ex,
    input stack_pop_mux_ex,
    input stack_push_ex,
    input stack_pop_ex,
    input [7:0] sp_value_ex , 
    output reg mem_reg_write,
    output reg mem_mem_read,
    output reg mem_mem_write,
    output reg [7:0]  mem_alu_result,
    output reg [7:0]  mem_write_data,
    output reg [1:0]  mem_rd,
    output reg [2:0]  wb_result_mux_mem,
    output reg [1:0]  mem_src_mem ,
    output reg [1:0] stack_push_mux_mem ,
    output reg stack_pop_mux_mem,
    output reg stack_push_mem,
    output [7:0] sp_value_mem , 
    output reg stack_pop_mem
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        mem_reg_write <= 0;
        mem_mem_read  <= 0;
        mem_mem_write <= 0;
        mem_alu_result <= 8'b0;
        mem_write_data <= 8'b0;
        mem_rd<=0;
        wb_result_mux_mem<=0;
        mem_src_mem<=0;
        stack_push_mem<=0;
        stack_push_mux_mem<=0;
        stack_pop_mem<=0;
        stack_pop_mux_mem<=0;
    end 
    else if (flush) begin
        mem_reg_write <= 0;
        mem_mem_read  <= 0;
        mem_mem_write <= 0;
        mem_alu_result  <= 8'b0;
        mem_write_data  <= 8'b0;
        mem_rd<=0;
        wb_result_mux_mem<=0;
        mem_src_mem<=0;
        stack_push_mem<=0;
        stack_push_mux_mem<=0;
        stack_pop_mem<=0;
        stack_pop_mux_mem<=0;
    end 
    else begin
        mem_reg_write <= ex_reg_write;
        mem_mem_read <= ex_mem_read;
        mem_mem_write <= ex_mem_write;
        mem_alu_result <= ex_alu_result;
        mem_write_data <= ex_write_data;
        mem_rd<= ex_reg_dist;
        wb_result_mux_mem <= wb_result_mux_ex;
        mem_src_mem<=mem_src_ex;
        stack_push_mem<=stack_push_ex;
        stack_push_mux_mem<=stack_pop_mux_ex;
        stack_pop_mem<=stack_pop_ex;
        stack_pop_mux_mem<=stack_pop_mux_ex;
    end
end
endmodule
