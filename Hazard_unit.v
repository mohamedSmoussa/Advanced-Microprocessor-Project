module hazard_unit #(
    parameter IGNORE_REG0 = 0  
) (
    input [1:0] id_rs,      
    input [1:0] id_rt,      
    input [1:0] ex_reg_dist,      
    input [1:0] mem_rd,     
    input [1:0] wb_rd,
    input [1:0] mem_src, // lazem ba3d el memory  stage msh abl    
    input ex_reg_write,     
    input mem_reg_write,
    input wb_reg_write, 
    input ex_mem_read,  // EX stage is a load  operation 
    output reg [1:0] forward_a,   
    output reg [1:0] forward_b,   
    output reg  stall        
);
    wire ex_eq_rs = (ex_reg_dist == id_rs)?1:0;    // dest in ex h7tago in next decode (RAW1)
    wire ex_eq_rt = (ex_reg_dist == id_rt)?1:0;    // dest in ex h7tago in next decode (RAW2)
    wire mem_eq_rs = (mem_rd == id_rs)?1:0;  // dest in mem h7tago feh deocode zy el load msln 
    wire mem_eq_rt = (mem_rd == id_rt)?1:0;  // dest in mem h7tago feh deocode zy el load msln (2)
    wire wb_eq_rs  = (wb_rd  == id_rs)?1:0;  // dest in wb h7tago feh decode 
    wire wb_eq_rt  = (wb_rd  == id_rt)?1:0;      // dest in wb h7tago feh decode (2)
    wire valid_ex_eq_rs = (IGNORE_REG0 && (id_rs == 2'b00)) ? 1'b0 : ex_eq_rs;
    wire valid_mem_eq_rs = (IGNORE_REG0 && (id_rs == 2'b00)) ? 1'b0 : mem_eq_rs;
    wire valid_wb_eq_rs  = (IGNORE_REG0 && (id_rs == 2'b00)) ? 1'b0 : wb_eq_rs;
    wire valid_ex_eq_rt = (IGNORE_REG0 && (id_rt == 2'b00)) ? 1'b0 : ex_eq_rt;
    wire valid_mem_eq_rt = (IGNORE_REG0 && (id_rt == 2'b00)) ? 1'b0 : mem_eq_rt;
    wire valid_wb_eq_rt  = (IGNORE_REG0 && (id_rt == 2'b00)) ? 1'b0 : wb_eq_rt;

    always @(*) begin
        if ((ex_mem_read && (valid_ex_eq_rs || valid_ex_eq_rt)) || (mem_src!=2'b00))
            stall = 1'b1;
        else
            stall = 1'b0;
    end
   // Priority
    always @(*) begin
        if (stall) begin
            forward_a = 2'b00; 
        end else begin
            if (ex_reg_write && valid_ex_eq_rs)
                forward_a = 2'b11; 
            else if (mem_reg_write && valid_mem_eq_rs)
                forward_a = 2'b01; 
            else if (wb_reg_write && valid_wb_eq_rs)
                forward_a = 2'b10; 
            else
                forward_a = 2'b00; 
        end
    end

    always @(*) begin
        if (stall) begin
            forward_b = 2'b00;
        end else begin
            if (ex_reg_write && valid_ex_eq_rt)
                forward_b = 2'b11;
            else if (mem_reg_write && valid_mem_eq_rt)
                forward_b = 2'b01;
            else if (wb_reg_write && valid_wb_eq_rt)
                forward_b = 2'b10;
            else
                forward_b = 2'b00;
        end
    end
endmodule
