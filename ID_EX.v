module id_ex_register (
    input clk,
    input rst,
    input flush, 
    input id_reg_write,
    input id_mem_read,
    input id_mem_write,
    input id_dec_ra,
    input [3:0]  id_alu_op,
    input [7:0]  id_read_data_a,
    input [7:0]  id_read_data_b,
    input [1:0]  id_rs,
    input [1:0]  id_rt,
    input [2:0] wb_result_mux, 
    input [1:0] stack_push_mux , 
    input stack_pop_mux,
    input stack_push,
    input stack_pop,
    input [1:0] reg_dist,
    input [1:0] mem_src,
    output reg ex_reg_write,
    output reg ex_mem_read,
    output reg ex_mem_write,
    output reg [3:0] ex_alu_op,
    output reg [7:0] ex_read_data_a,
    output reg [7:0] ex_read_data_b,
    output reg [1:0] ex_rs,
    output reg [1:0] ex_rt,
    output reg ex_dec_ra,
    output reg [1:0] ex_reg_dist,
    output reg [2:0] wb_result_mux_ex,
    output reg [1:0] mem_src_ex,
    output reg [1:0] stack_push_mux_ex ,
    output reg stack_pop_mux_ex,
    output reg stack_push_ex,
    output reg stack_pop_ex
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        ex_reg_write <= 0;
        ex_mem_read  <= 0;
        ex_mem_write <= 0;
        ex_alu_op    <= 4'b0;
        ex_read_data_a <= 8'b0;
        ex_read_data_b <= 8'b0;
        ex_rs <= 2'b0;
        ex_rt <= 2'b0;
        ex_dec_ra <=0;
        ex_reg_dist<= 0;
        wb_result_mux_ex<=0;
        mem_src_ex<=0;
        stack_push_ex<=0;
        stack_push_mux_ex<=0;
        stack_pop_ex<=0;
        stack_pop_mux_ex<=0;

    end 
    else if (flush) begin
        ex_reg_write <= 0;
        ex_mem_read  <= 0;
        ex_mem_write <= 0;
        ex_alu_op  <= 4'b0;
        ex_read_data_a <= 8'b0;
        ex_read_data_b <= 8'b0;
        ex_rs <= 2'b0;
        ex_rt <= 2'b0;
        ex_dec_ra <=0;
        ex_reg_dist <= 0;
        wb_result_mux_ex<=0;
        mem_src_ex<=0;
        stack_push_ex<=0;
        stack_push_mux_ex<=0;
        stack_pop_ex<=0;
        stack_pop_mux_ex<=0;
    end 
    else begin
        ex_reg_write <= id_reg_write;
        ex_mem_read  <= id_mem_read;
        ex_mem_write <= id_mem_write;
        ex_alu_op  <= id_alu_op;
        ex_read_data_a <= id_read_data_a;
        ex_read_data_b <= id_read_data_b;
        ex_rs <= id_rs;
        ex_rt <= id_rt;
        ex_dec_ra <= id_dec_ra;
        ex_reg_dist<=reg_dist;
        wb_result_mux_ex<=wb_result_mux;
        mem_src_ex<=mem_src;
        stack_push_ex<=stack_push;
        stack_push_mux_ex<=stack_pop_mux;
        stack_pop_ex<=stack_pop;
        stack_pop_mux_ex<=stack_pop_mux;
    end
end
endmodule
