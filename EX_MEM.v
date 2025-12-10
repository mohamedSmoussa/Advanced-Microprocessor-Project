module ex_mem_register (
    input clk,
    input rst,
    input flush,  
    input ex_reg_write,
    input ex_mem_read,
    input ex_mem_write,
    input   [7:0]  ex_alu_result,
    input   [7:0]  ex_write_data,   
    input [1:0]  ex_rd,
    input  [7:0]  ex_pc,
    output reg mem_reg_write,
    output reg mem_mem_read,
    output reg mem_mem_write,
    output reg [7:0]   mem_alu_result,
    output reg [7:0]   mem_write_data,
    output reg [1:0]   mem_rd,
    output reg [7:0]   mem_pc
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        mem_reg_write <= 0;
        mem_mem_read  <= 0;
        mem_mem_write <= 0;
        mem_alu_result <= 8'b0;
        mem_write_data <= 8'b0;
        mem_rd <= 2'b0;
        mem_pc <= 8'b0;
    end 
    else if (flush) begin
        mem_reg_write <= 0;
        mem_mem_read  <= 0;
        mem_mem_write <= 0;
        mem_alu_result  <= 8'b0;
        mem_write_data  <= 8'b0;
        mem_rd <=2'b0;
        mem_pc <=8'b0;
    end 
    else begin
        mem_reg_write <= ex_reg_write;
        mem_mem_read <= ex_mem_read;
        mem_mem_write <= ex_mem_write;
        mem_alu_result <= ex_alu_result;
        mem_write_data <= ex_write_data;
        mem_rd <= ex_rd;
        mem_pc <= ex_pc;
    end
end
endmodule
