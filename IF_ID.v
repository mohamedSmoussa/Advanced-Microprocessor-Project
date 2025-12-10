module if_id_register (
    input  clk,
    input  rst,
    input  stall,  
    input  flush,  
    input  [7:0]  if_instruction,
    input  [7:0]  if_pc,
    output reg  [7:0]  id_instruction,
    output reg  [7:0]  id_pc
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        id_instruction <= 8'b0;
        id_pc <= 8'b0;
    end 
    else if (flush) begin
        id_instruction <= 8'b0;
        id_pc<= 8'b0;
    end
    else if (!stall) begin
        id_instruction <= if_instruction;
        id_pc          <= if_pc;
    end
end
endmodule
