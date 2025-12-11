module top_module(
    input clk,
    input rst,
    input interrupt,
    input [7:0] in_port ,
    output [7:0] out_port
);
wire pc_write;
wire ir_write;
wire imm_write;
wire stall;
wire [2:0]  pc_src;         
wire [7:0]  pc_branch;
wire [7:0]  pc_stack;
wire [7:0]  mem_data;     // mem_data = M[PC] or M[p
wire [7:0] interrupt_addr;  // M[1]
wire  [7:0]  PC;
wire  [7:0]  IR;
wire  [7:0]  imm;
wire [7:0]  PC_plus_1;
wire [7:0]  PC_plus_2;



fetch_unit f_module (
    .clk(clk),
    .rst(rst),

    // Control Unit
     .pc_write(pc_write),
     .ir_write(ir_write),
     .imm_write(imm_write),
     .stall(stall),
     .pc_src(pc_src),         
     .pc_branch(pc_branch),
     .pc_stack(pc_stack),

    // Memory interface
      .mem_data(mem_data),     // mem_data = M[PC] or M[pc+1]

    // Interrupt Handling
     .interrupt_addr(interrupt_addr),   // M[1]

    // Outputs to pipeline
      .PC(PC),
      .IR(IR),
      .imm(imm),

     .PC_plus_1(PC_plus_1),
     .PC_plus_2(PC_plus_2)
);
wire flush ;
wire [7:0]  if_instruction;
wire [7:0]  id_instruction;
 if_id_register decode_pipe(
     .clk(clk),
     .rst(rst),
     .stall(stall),  
     .flush(flush),  
      .if_instruction(if_instruction),
      .id_instruction(id_instruction)
);

  wire  [3:0] alu_op;
  wire  dec_ra;
  wire reg_write;      
  wire [1:0] reg_dist; 
  wire [2:0] wb_result_mux; 
  wire mem_read;
  wire mem_write;
  wire [1:0] mem_src; 
  wire [1:0] stack_push_mux ; 
  wire stack_pop_mux ;  
  wire stack_push;
  wire stack_pop;
  wire setc;                 
  wire clrc;                 
  wire save_flags;           
  wire restore_flags;        
  wire port_out_write;
  wire port_in_read;
  wire is_two_byte; 
  wire is_loop ;        
  wire interrupt_save ;  

control_unit cu_module(
    // Inputs
     .clk(clk),
     .rst(rst),
     .instruction(id_instruction),
     .z_flag(z_flag),                 
     .n_flag(n_flag),                 
     .c_flag(c_flag),                 
     .v_flag(v_flag),                 
     .interrupt(interrupt),
     .alu_op(alu_op),
     .dec_ra(dec_ra), 
     .reg_write(reg_write),       
     .reg_dist(reg_dist), 
     .wb_result_mux(wb_result_mux), 
     .mem_read(mem_read),
     .mem_write(mem_write),
     .mem_src(mem_src),
      .stack_push_mux(stack_push_mux) , 
     .stack_pop_mux(stack_pop_mux) , 
     .pc_write(pc_write), 
      .pc_src(pc_src), 
     .ir_write(ir_write),    
     .imm_write(imm_write),  
     .stack_push(stack_push),
     .stack_pop(stack_pop),
     .setc(setc),                   
     .clrc(clrc),                   
     .save_flags(save_flags),             
     .restore_flags(restore_flags),          
     .port_out_write(port_out_write),
     .port_in_read(port_in_read),
     .is_two_byte(is_two_byte),        
     .is_loop(is_loop) ,           
     .flush(flush),              
     .interrupt_save(interrupt_save) 
);

wire wb_reg_write;
wire [1:0] wb_reg_dist;
wire [7:0] wb_result;
wire [7:0]  read_data_a ,  read_data_b, sp_value ;
  register_file  reg_file_module(
    .clk(clk),
    .rst(rst),
    .write_en(wb_reg_write),
    .read_addr_a(id_instruction[3:2]),
    .read_addr_b(id_instruction[1:0]), 
    .write_addr(wb_reg_dist),
    .write_data(wb_result),
    .read_data_a(read_data_a),
    .read_data_b(read_data_b), 
     .sp_value(sp_value)
);


wire ex_reg_write ;
wire ex_mem_read;
wire ex_mem_write;
wire [3:0] ex_alu_op;
wire [7:0] ex_read_data_a;
wire [7:0] ex_read_data_b;
wire [1:0] ex_rs;
wire [1:0] ex_rt;
wire ex_dec_ra;
wire [1:0] ex_reg_dist;
wire [2:0] wb_result_mux_ex;
wire [1:0] mem_src_ex;
wire [1:0] stack_push_mux_ex ;
wire stack_pop_mux_ex;
wire stack_push_ex;
wire stack_pop_ex;

 id_ex_register ex_module(
     .clk(clk),
     .rst(rst),
     .flush(flush), 
     .id_reg_write(reg_write),
     .id_mem_read(mem_read),
     .id_mem_write(mem_write),
     .id_dec_ra(dec_ra),
      .id_alu_op(alu_op),
      .id_read_data_a(read_data_a),
      .id_read_data_b(read_data_b),
      .id_rs(id_instruction[3:2]),
      .id_rt(id_instruction[1:0]),
      .wb_result_mux(wb_result_mux), 
      .stack_push_mux(stack_push_mux) , 
      .stack_pop_mux(stack_pop_mux),
      .stack_push(stack_push),
      .stack_pop(stack_pop),
      .reg_dist(reg_dist),
      .mem_src(mem_src),
      .ex_reg_write(ex_reg_write),
      .ex_mem_read(ex_mem_read),
      .ex_mem_write(ex_mem_write),
      .ex_alu_op(ex_alu_op),
      .ex_read_data_a(ex_read_data_a),
      .ex_read_data_b(ex_read_data_b),
      .ex_rs(ex_rs),
      .ex_rt(ex_rt),
      .ex_dec_ra(ex_dec_ra),
      .ex_reg_dist(ex_reg_dist),
      .wb_result_mux_ex(wb_result_mux_ex),
      .mem_src_ex(mem_src_ex),
      .stack_push_mux_ex(stack_push_mux_ex) ,
      .stack_pop_mux_ex(stack_pop_mux_ex),
      .stack_push_ex(stack_push_ex),
      .stack_pop_ex(stack_pop_ex)
);

















endmodule 

















/*
module mem_wb_register (
    input  clk
    input  rst,
    input  flush,  
    input  mem_reg_write,
    input  [7:0]  mem_result,  //
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
*/