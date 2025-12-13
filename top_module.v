module top_module(
    input clk,
    input rst,
    input interrupt,
    input [7:0] in_port ,
    output [7:0] out_port
);

    // Fetch
    wire pc_write;
    wire ir_write;
    wire imm_write;
    wire stall;
    wire [2:0]  pc_src;         
    wire [7:0]  pc_branch;
    wire [7:0]  pc_stack;
    wire [7:0]  mem_data;   
    wire [7:0] interrupt_addr;  
    wire [7:0]  PC;
    wire [7:0]  IR;
    wire [7:0]  imm;
    wire [7:0]  PC_plus_1;
    wire [7:0]  PC_plus_2;

    // IF/ID REG
    wire flush ;
    wire [7:0]  if_instruction;
    wire [7:0]  id_instruction;

    // ------------------CONTROL UNIT ---------------------------//
    wire [3:0] alu_op;
    wire dec_ra;
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
    wire z_flag ;  
    wire n_flag ;  
    wire c_flag ;  
    wire v_flag ;  

    // MEM/WB
    wire wb_reg_write;
    wire [1:0] wb_reg_dist;
    wire [7:0] wb_result;
    wire [7:0]  read_data_a ,  read_data_b, sp_value ;
    // ID/EX
    wire flush; 
    wire id_reg_write;
    wire id_mem_read;
    wire id_mem_write;
    wire id_dec_ra;
    wire [3:0] id_alu_op;
    wire [7:0] id_read_data_a;
    wire [7:0] id_read_data_b;
    wire [1:0] id_rs;
    wire [1:0] id_rt;
    wire [2:0] wb_result_mux; 
    wire [1:0] stack_push_mux ; 
    wire stack_pop_mux;
    wire stack_push;
    wire stack_pop;
    wire [1:0] reg_dist;
    wire [1:0] mem_src;
    wire ex_reg_write;
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
    wire [1:0] stack_push_mux_ex;
    wire stack_pop_mux_ex;
    wire stack_push_ex;
    wire stack_pop_ex;
    wire ex_setc;
    wire ex_clrc;
    wire setc;
    wire clrc;
    wire [7:0] sp_value_ex ; 
     //--------------------EXCUTE STAGE---------------------//

    wire [1:0] ex_rd;      
    wire [1:0] mem_rd;     
    wire [1:0] wb_rd;
    wire [1:0] mem_src;   
    wire ex_reg_write;     
    wire mem_reg_write;
    wire wb_reg_write; 
    wire ex_mem_read;  
    wire [1:0] forward_a;   
    wire [1:0] forward_b;   
    wire stall;        
    // ALU
    wire [7:0] operand_a, operand_b;
    wire [3:0] alu_op;
    wire [1:0] ra_field;
    wire c_in, dec_ra;
    wire old_c_flag, old_v_flag, old_z_flag, old_n_flag;
    wire [7:0] result;
    wire z_flag_alu_out,n_flag_alu_out,c_flag_alu_out,v_flag_alu_out,flags_update;
    // Flags REG
    wire update_flags,z_in,n_in,c_in,v_in,setc,clrc,restore_flags;
    wire [3:0] restore_flags_value;
    wire [3:0] flags_out;
    // EX/MEM
    wire ex_reg_write;
    wire ex_mem_read;
    wire ex_mem_write;
    wire [7:0] ex_alu_result;
    wire [7:0] ex_write_data;   
    wire [1:0] ex_reg_dist;
    wire [2:0] wb_result_mux_ex;
    wire [1:0] mem_src_ex;
    wire [1:0] stack_push_mux_ex;
    wire stack_pop_mux_ex;
    wire stack_push_ex;
    wire stack_pop_ex;
    wire mem_reg_write;
    wire mem_mem_read;
    wire mem_mem_write;
    wire [7:0] mem_alu_result;
    wire [7:0] mem_write_data;
    wire [1:0] mem_rd;
    wire [2:0] wb_result_mux_mem;
    wire [1:0] mem_src_mem ;
    wire [1:0] stack_push_mux_mem ;
    wire stack_pop_mux_mem;
    wire stack_push_mem;
    wire [7:0] sp_value_mem ;
    wire stack_pop_mem;
    //----------------------MEMORY STAGE ------------------------------//

    wire mem_en;                       // Memory enable (from CU; active in MEM stage)
    wire mem_read;                     // Read control (from CU; combo out)
    wire mem_write;                    // Write control (from CU; sync write)
    
    wire port_sel;                     // 1=I/O ports (IN/OUT); 0=memory/stack (from CU)
    wire [7:0] mem_addr;               // Base address [7:0] (PC/ea from EX/Fetch)
    wire [7:0] mem_data_in;            // Write data [7:0] (R[rb]/imm/PC/flags from datapath
    wire [3:0] stack_ctrl;             // Stack op [3:0] from CU: 0000=none; 0001=PUSH; 0010=POP;
                                            // 0011=CALL (push PC+1); 0100=RET (pop PC); 0101=RTI (pop PC+flags);
                                            // 0110=INTR_push (push PC+flags seq); 0111=INTR_flags (2nd push for flags)
    wire [7:0] sp;                     // Current SP [7:0] from RegFile (R3)
    wire stack_push;
    wire stack_pop;
    wire [7:0] pc;                     // PC [7:0] for CALL/INTR push (from Fetch/PC unit)
    wire [3:0] ccr_in;                 // CCR flags [3:0] (V=3;C=2;N=1;Z=0) for RTI/INTR push (from Flags)
    wire [7:0] in_port;                // External IN_PORT [7:0] (top-level input)
    wire [7:0] sp_out;
    wire [7:0] mem_data_out;           // Read data [7:0] (to RegFile/PC mux in WB/EX)
    wire [7:0] out_port;               // OUT_PORT [7:0] (top-level output, latched)
    wire [3:0] ccr_out;                 // Restored CCR [3:0] for RTI (to Flags Unit)
    wire [7:0]  imm_ea; 
    wire [7:0]  instr;   
    // MEM/WB
    wire  [7:0]  mem_result;  
    wire wb_reg_write;
    wire [7:0] wb_result;
    wire [1:0]  wb_reg_dist;
    wire [2:0]  wb_result_mux;
    wire stack_pop_wb ; 
    wire stack_push_wb ; 

    if_id_register decode_pipe(
        // INPUTS 
        .clk(clk),
        .rst(rst),
        .stall(stall),  
        .flush(flush),  
        .if_instruction(if_instruction),
        //OUTPUT
        .id_instruction(id_instruction)
    );

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
        // OUTPUTS              
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
        .flush(flush),              
        .interrupt_save(interrupt_save) 
    );
    //------------------------------------FETCH UNIT---------------------------// 
    fetch_unit f_module (
        // INPUTS 
        .clk(clk),
        .rst(rst),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .imm_write(imm_write),
        .stall(stall),
        .pc_src(pc_src),         
        .pc_branch(ex_read_data_b),
        .pc_stack(mem_data_out),
        .mem_data(mem_data_out), 
        .interrupt_addr(mem_data_out),
        // OUTPUTS
        .PC(PC),
        .IR(IR),
        .imm(imm),
        .PC_plus_1(PC_plus_1),
        .PC_plus_2(PC_plus_2)
    );

    register_file  reg_file_module(
        //INPUTS
        .clk(clk),
        .rst(rst),
        .write_en(wb_reg_write),
        .read_addr_a(id_instruction[3:2]),
        .read_addr_b(id_instruction[1:0]), 
        .write_addr(wb_reg_dist),
        .write_data(wb_result),
        .stack_pop (stack_pop_wb ), 
        .stack_push (stack_push_wb), 
        //OUTPUTS
        .read_data_a(read_data_a),
        .read_data_b(read_data_b), 
        .sp_value(sp_value)
    );


    id_ex_register ex_module(
        //INPUTS
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
        // .wb_result_mux(wb_result_mux), 
        .stack_push_mux(stack_push_mux), 
        .stack_pop_mux(stack_pop_mux),
        .stack_push(stack_push),
        .stack_pop(stack_pop),
        .reg_dist(reg_dist),
        .mem_src(mem_src),
        .setc(setc),
        .clrc(clrc),
        .sp_value (sp_value) , 
        // OUTPUTS
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
        // .wb_result_mux_ex(wb_result_mux_ex),
        .mem_src_ex(mem_src_ex),
        .stack_push_mux_ex(stack_push_mux_ex) ,
        .stack_pop_mux_ex(stack_pop_mux_ex),
        .stack_push_ex(stack_push_ex),
        .stack_pop_ex(stack_pop_ex)
        .ex_setc(ex_setc),                
        .ex_clrc(ex_clrc) , 
        ,sp_value_ex (sp_value_ex)
    );


    hazard_unit hazard_unit_inst (
        .id_rs(id_instruction[3:2]),
        .id_rt(id_instruction[1:0]),
        .mem_rd(mem_rd),
        .wb_rd(wb_rd),
        .mem_src(mem_src),
        .ex_reg_write(ex_reg_write),
        .mem_reg_write(mem_reg_write),
        .wb_reg_write(wb_reg_write),
        .ex_mem_read(ex_mem_read),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .stall(stall)       
    );

    // Forward Multiplexers for ALU operands
    assign forward_oper_a = (forward_a == 2'b00) ? /* */ :
                                  (forward_a == 2'b01) ? /* */  :
                                  (forward_a == 2'b10) ? /* */  : /* */; 
    assign forward_oper_b = (forward_b == 2'b00) ? /* */ :
                                  (forward_b == 2'b01) ? /* */  :
                                  (forward_b == 2'b10) ? /* */  : /* */; 


    alu alu_inst (
        .operand_a(forward_oper_a),
        .operand_b(forward_oper_b),
        .alu_op(ex_alu_op),
        .ra_field(ex_rs),
        .c_in(c_flag),
        .dec_ra(ex_dec_ra),
        .old_c_flag(c_flag),
        .old_v_flag(v_flag),
        .old_z_flag(z_flag),
        .old_n_flag(n_flag),
        .result(result),
        .z_flag_alu_out(z_flag_alu_out),                 
        .n_flag_alu_out(n_flag_alu_out),                 
        .c_flag_alu_out(c_flag_alu_out),                 
        .v_flag_alu_out(v_flag_alu_out),                 
        .flags_update(flags_update)                
    ); 


    flags_reg flag_inst(
        //INPUTS
        .clk(clk),                
        .rst(rst),                
        .update_flags(flags_update),                
        .z_in(z_flag_alu_out),                
        .n_in(n_flag_alu_out),                
        .c_in(c_flag_alu_out),                
        .v_in(v_flag_alu_out),           
        .setc(ex_setc),                
        .clrc(ex_clrc),             
        .save_flags(save_flags),             
        .restore_flags(restore_flags),   // Should be in pipeline registers             
        // .restore_flags_value(restore_flags_value),     
        //OUTPUTS
        .z_flag(z_flag),                
        .n_flag(n_flag),                
        .v_flag(v_flag),                
        .c_flag(c_flag),                
        .flags_out(flags_out)                
    );


    ex_mem_register mem_stage_reg(
        //INPUTS
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_alu_result(result),
        .ex_write_data(forward_oper_b),
        .ex_reg_dist(ex_reg_dist),
        .wb_result_mux_ex(wb_result_mux_ex),
        .mem_src_ex(mem_src_ex),
        .stack_push_mux_ex(stack_push_mux_ex),                 
        .stack_pop_mux_ex(stack_pop_mux_ex),                 
        .stack_push_ex(stack_push_ex),                 
        .stack_pop_ex(stack_pop_ex),    
        .sp_value_ex (sp_value_ex) ,
        // outputs             
        .mem_reg_write(mem_reg_write),                
        .mem_mem_read(mem_mem_read),                
        .mem_mem_write(mem_mem_write),                
        .mem_alu_result(mem_alu_result),                
        .mem_write_data(mem_write_data),                
        .mem_rd(mem_rd),                
        .wb_result_mux_mem(wb_result_mux_mem),                
        .mem_src_mem(mem_src_mem),                
        .stack_push_mux_mem(stack_push_mux_mem),                
        .stack_pop_mux_mem(stack_pop_mux_mem),                
        .stack_push_mem(stack_push_mem),                
        .stack_pop_mem(stack_pop_mem) , 
        .sp_value_mem (sp_value_mem)           
    );


    // Memory Address Multiplexer
    assign mem_address = (mem_src_mem == 2'b00) ? pc :              // PC (fetch)
                         (mem_src_mem == 2'b01) ? mem_alu_result : // Register (ra)
                         (mem_src_mem == 2'b10) ? sp_value_mem :   // Stack pointer
                                    imm;                           // Immediate
    
    // Stack Push Data Multiplexer
    assign stack_push_data = (stack_push_mux_mem == 2'b00) ? mem_write_data :  // Rb
                             (stack_push_mux_mem == 2'b01) ? PC_plus_1 :   // PC+1
                               PC;                                        // PC                          

   memory_stack mem(
        .clk(clk),                
        .rst(rst),                
        .mem_en(mem_en),                
        .mem_read(mem_read),                
        .mem_write(mem_write),                
        .port_sel(port_sel),                
        .mem_addr(mem_addr),                
        .mem_data_in(mem_data_in),                
        .stack_ctrl(stack_ctrl),                
        .sp(sp),                
        .stack_push(stack_push),                
        .stack_pop(stack_pop),                
        .pc(pc),                
        .ccr_in(ccr_in),                
        .sp_out(sp_out),                
        .mem_data_out(mem_data_out),                
        .out_port(out_port),                
        .ccr_out(ccr_out),                
        .imm_ea(imm_ea),                
        .instr(instr)              
    );

    assign mem_result = (wb_result_mux_mem == 3'b000) ? /* memory output port */ :
                                  (wb_result_mux_mem == 3'b001) ? imm // doesnt matter as it will never be 1   :
                                  (wb_result_mux_mem == 3'b010) ? imm   : 
                                (wb_result_mux_mem == 3'b011)  ?   mem_alu_result :  in_port ;                            

    mem_wb_register wb_stage_reg(
        // inputs
        .clk(clk),                
        .rst(rst),                
        .flush(flush),                
        .mem_reg_write(mem_reg_write),                
        .mem_result(mem_result),                
        .mem_rd(mem_rd),  
        .stack_pop_mem (stack_pop_mem) , 
        .stack_push_mem (stack_push_mem) , 
        // outputs                             
        .wb_reg_write(wb_reg_write),                
        .wb_result(wb_result),                
        .wb_reg_dist(wb_reg_dist)  ,   
        .stack_pop_wb (stack_pop_wb)    , 
        .stack_push_wb (stack_push_wb)                    
    );

endmodule          