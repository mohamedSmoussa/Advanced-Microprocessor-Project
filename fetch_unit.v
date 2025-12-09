module fetch_unit (
    input wire clk,
    input wire rst,

    // Control Unit
    input wire pc_write,
    input wire ir_write,
    input wire imm_write,
    input wire stall,
    input wire [2:0]  pc_src,         
    input wire [7:0]  pc_branch,
    input wire [7:0]  pc_stack,

    // Memory interface
    input wire [7:0]  mem_data,     // mem_data = M[PC] or M[pc+1]

    // Interrupt Handling
    input wire [7:0] interrupt_addr,   // M[1]

    // Outputs to pipeline
    output reg  [7:0]  PC,
    output reg  [7:0]  IR,
    output reg  [7:0]  imm,

    output wire [7:0]  PC_plus_1,
    output wire [7:0]  PC_plus_2
);

    reg [7:0] next_pc;

    assign PC_plus_1 = PC + 1;
    assign PC_plus_2 = PC + 2;

    // pc mux
    always @(*) begin
        case (pc_src)
            3'b000: next_pc = PC_plus_1;    // Normal: 1-byte instruction
            3'b001: next_pc = PC_plus_2;    // 2-byte instruction
            3'b010: next_pc = pc_branch;    // Branch target / CALL
            3'b011: next_pc = pc_stack;     // Return from interrupt
            3'b100: next_pc = mem_data;     // Reset vector (PC ← M[0])
            3'b101: next_pc = interrupt_addr;     // Interrupt vector (PC ← M[1])
            default: next_pc = PC_plus_1;
        endcase
    end

    // program counter register
    always @(posedge clk or posedge rst) begin
        if (rst)
            PC <= 8'd0;               // Reset begins by reading M[0]
        else if (!stall && pc_write)
            PC <= next_pc;            // Normal PC update
    end

    // instruction register
    always @(posedge clk or posedge rst) begin
        if (rst)
            IR <= 8'd0;
        else if (ir_write)
            IR <= mem_data;           // mem_data = M[pc]
    end

    // Immediate Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            imm <= 8'd0;
        else if (imm_write)
            imm <= mem_data;          // mem_data = M[pc+1]      (if needed)
    end


endmodule //fetch_unit