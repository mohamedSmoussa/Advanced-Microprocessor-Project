module control_unit(
    // Inputs
    input clk,
    input rst,
    input [7:0] instruction, // Current instruction from ID stage
    input z_flag,                  // Zero flag from Flags Register
    input n_flag,                  // Negative flag
    input c_flag,                  // Carry flag
    input v_flag,                  // Overflow flag
    input interrupt,
    // -------------Control Signals-------------
    // ALU Control
    output reg [3:0] alu_op,
    output reg dec_ra, // (NEW SIGNAL ADDED) If dec_ra = 1 -> decrement ra else -> Normal unary operation (ADD this signal in ALU)
    // Register File Control
    output reg reg_write,       // Register write enable
    output reg [1:0] reg_dist, // Destination register (ra or rb) (NEW SIGNAL ADDED)
    output reg [2:0] wb_result_mux, // (NEW SIGNAL ADDED) 0: mem, 1: pc, 2: immediate, 3: alu_result , 4: IN port
    // Memory Control
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] mem_src, // (NEW SIGNAL ADDED) Selections of MUX at mem address signal in memory-> 0: PC, 1: Register file(ra), 2: SP, 3: Immediate register
    output reg [1:0] stack_push_mux , // (NEW SIGNAL ADDED) mux to switch between PC and Rb for the stack to push , 0 : Rb , 1 : PC+1 , 2 : PC
    output reg stack_pop_mux , // (NEW SIGNAL ADDED) mux to switch between PC and Rb for the stack to pop , 0 : Rb , 1 : PC
    // PC Control
    output reg pc_write, 
    output reg [2:0] pc_src, // MUX in Fetch unit to select output of pc-> 0: PC+1 , 1: PC+2 , 2: Branch [PC←Rb] , 3: Stack , 4: M[0], 5: M[1]
    output reg ir_write,    //Instruction register write control signal
    output reg imm_write,  //Immediate register write control signal
    // Stack Control
    output reg stack_push,
    output reg stack_pop,
    // Flags Control
    output reg setc,                   // Set carry flag
    output reg clrc,                   // Clear carry flag
    output reg save_flags,             // Save flags for interrupt
    output reg restore_flags,          // Restore flags from interrupt
    // I/O Control
    output reg port_out_write,
    output reg port_in_read,
    // States Control
    output reg is_two_byte,            // Two-byte instruction indicator
    output reg is_loop ,             // LOOP instruction indicator (Makes transition to LOOP_DECIDE state )
    output reg flush,               // Flush IF stage
    // Interrupt Control
    output reg interrupt_save          // Save context for interrupt
);

    // States (4 States)
    // FSM to handle (2 byte fetch and interrupt and loop decision )
    localparam IDLE        = 2'd0;  // Normal pipeline operation
    localparam FETCH2     = 2'd1;  // Fetching second byte
    localparam INT_HANDLE  = 2'd2;  // Handling interrupt
    localparam LOOP_DECIDE = 2'd3 ; //Handling loop condition desicion

    // Current and next state
    reg [1:0] cs, ns; 

    // Instruction fields
    wire [3:0] opcode = instruction[7:4];  // 4-bit opcode
    wire [1:0] ra     = instruction[3:2];  // Register A field
    wire [1:0] rb     = instruction[1:0];  // Register B field
    wire [1:0] brx    = instruction[3:2];  // Branch index (same as ra)

    // A-Format instruction opcodes
    localparam NOP = 4'd0; localparam MOV = 4'd1;
    localparam ADD = 4'd2; localparam SUB = 4'd3;
    localparam AND = 4'd4; localparam OR  = 4'd5;
    localparam ROT_CARRY_OP = 4'd6; // RLC, RRC, SETC, CLRC
    localparam STACK_IO_OP  = 4'd7; // PUSH, POP, OUT, IN
    localparam UNARY_OP     = 4'd8; // NOT, NEG, INC, DEC
    // B-Format instruction opcodes
    localparam COND_BRANCHES = 4'd9; // JZ, JN, JC, JV
    localparam LOOP          = 4'd10;
    localparam JUMP          = 4'd11; // JMP, CALL, RET, RTI
    // L-Format instruction opcodes
    localparam LOAD_STORE    = 4'd12; // LDM, LDD, STD
    localparam LDI           = 4'd13;
    localparam STI           = 4'd14;
    // ALU operations opcodes (Should be implemented in ALU)
    localparam ALU_PASS_B = 4'd1;  // For MOV instruction
    localparam ALU_ADD = 4'd2; localparam ALU_SUB = 4'd3;
    localparam ALU_AND = 4'd4; localparam ALU_OR  = 4'd5;
    localparam ALU_RLC = 4'd6; localparam ALU_RRC = 4'd6;
    localparam ALU_UNARY  = 4'd8;

    // State memory
    always @(posedge clk) begin
        if (rst)
            cs <= IDLE;
        else
            cs <= ns;
    end

    // FSM next state logic
    always @(*) begin
        case (cs)
            IDLE: begin
                if (interrupt) 
                    ns = INT_HANDLE;
                else if (is_two_byte) 
                    ns = FETCH2;
                else if (is_loop) 
                    ns = LOOP_DECIDE ; 
                else 
                    ns = IDLE;
            end
            FETCH2: begin
                if (interrupt) 
                    ns = INT_HANDLE;
                else
                    ns = IDLE; 
            end
            INT_HANDLE: begin
                ns = IDLE;
            end
            LOOP_DECIDE : begin 
                if (interrupt) 
                    ns = INT_HANDLE ; 
                else 
                    ns = IDLE ; 
            end
            default: ns = IDLE;
        endcase
    end

    // Output logic (Generate Control Signals) (Decoder)
    always @(*) begin

        // Default values
        alu_op = 4'h0; reg_write = 0; mem_read = 0;
        mem_write = 0; ir_write = 0; pc_write = 0; is_loop = 0;
        pc_src = 3'd0; stack_push = 0; stack_pop = 0; wb_result_mux = 0;
        setc = 0; clrc = 0; dec_ra = 0; mem_src = 0; reg_dist = 0;
        save_flags = 0; restore_flags = 0; port_out_write = 0; port_in_read = 0;
        is_two_byte = 0; interrupt_save = 0; flush = 0; mem_src = 0 ; 
        ir_write = 0; stack_push_mux = 0 ; imm_write = 0 ; stack_pop_mux = 0 ;
        case (cs)
            FETCH2 : begin
                mem_read = 1;           // Read second byte from memory
                mem_src = 0;        // Address from PC
                ir_write = 1;           
                imm_write = 0;          
                pc_write = 1;           
                pc_src = 3'd0;          // Total = PC+2
            end
            INT_HANDLE : begin
                // Save PC and flags, jump to interrupt vector
                // CRITICAL: When interrupt occurs:
                // 1. FLUSH the instruction that was just fetched (it will be re-executed after RTI)
                // 2. Save current PC to stack
                // 3. Save flags
                // 4. Jump to interrupt handler at M[1]
                interrupt_save = 1;
                save_flags = 1;
                stack_push = 1;
                stack_push_mux = 1; // Push PC to stack
                mem_write = 1;  // Push PC to stack
                mem_src = 2'b10; // Stack pointer address
                pc_write = 1;
                pc_src = 3'd5; // PC ← M[1] (interrupt vector)
                mem_read = 1;  // Read interrupt vector
                flush = 1; // Flush the pipeline
            end
            LOOP_DECIDE : begin // In this state loop branching condition is evaluated  (Desicion of jump or not is taken)
                pc_write = 1 ; 
                ir_write = 1 ; 
                mem_read = 1 ; 
                mem_src = 0 ; //PC source 
                if (!z_flag) begin
                    pc_src = 2; // [PC←Rb]
                    flush = 1;
                end
                else 
                    pc_src = 0 ; // PC+1 
            end
            IDLE : begin
                imm_write = 0; 
                ir_write = 1 ;
                case (opcode)
                // ------------- A-FORMAT ----------- // 
                    NOP : begin // PC ← PC + 1 
                        mem_read = 1;
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                    end
                    MOV : begin // R[ra] ← R[rb]
                        mem_read = 1;
                        reg_write = 1;
                        alu_op = ALU_PASS_B; // Pass operand B should implement this case in alu
                        reg_dist = ra;
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                        wb_result_mux = 3; 
                    end
                    ADD : begin // R[ra] ←R[ra] + R[rb]
                        alu_op = ALU_ADD;
                        mem_read = 1;
                        reg_write = 1;
                        reg_dist = ra;
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                        wb_result_mux = 3;
                    end
                    SUB : begin // R[ra] ←R[ra] – R[rb]
                        alu_op = ALU_SUB;
                        mem_read = 1;
                        reg_write = 1;
                        reg_dist = ra;
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                        wb_result_mux = 3;
                    end
                    AND : begin // R[ra] ←R[ra] AND R[rb]
                        alu_op = ALU_AND;
                        mem_read = 1;
                        reg_write = 1;
                        reg_dist = ra;
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                        wb_result_mux = 3;
                    end
                    OR : begin // R[ra] ←R[ra] OR R[rb]
                        alu_op = ALU_OR;
                        mem_read = 1;
                        reg_dist = ra;
                        reg_write = 1;
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                        wb_result_mux = 3;
                    end
                    ROT_CARRY_OP : begin
                        pc_write = 1;
                        pc_src = 3'd0; // PC + 1
                        mem_read = 1;
                        case (ra)
                            2'd0 : begin // RLC (C ←R[rb]<7>; R[rb] ← R[rb]<6:0>&C;)
                                alu_op = ALU_RLC;
                                reg_write = 1;
                                reg_dist = rb;
                                wb_result_mux = 3;
                            end
                            2'd1 : begin // RRC ( C ←R[rb]<0>; R[rb] ←C&R[rb]<7:1>;)
                                alu_op = ALU_RRC;
                                reg_write = 1;
                                reg_dist = rb;
                                wb_result_mux = 3;
                            end
                            2'd2 : begin // SETC C ←1;
                                setc = 1;
                            end
                            2'd3 : begin // CLRC C ←0;
                                clrc = 1;
                            end
                        endcase
                    end
                    STACK_IO_OP : begin
                        case (ra)
                            2'b00: begin  // PUSH X[SP--] ← R[rb]
                                stack_push = 1;
                                mem_read = 1;
                                mem_write = 1;
                                mem_src = 2'b10;  // SP address
                                // ==>>>Stall For Double memory access [Handle in hazard depending on mem_src ]
                                pc_write = 1;
                                pc_src = 3'd0;
                                stack_push_mux = 0 ;  // Push into Rb
                            end
                            2'b01: begin  // POP   R[rb] ← X[++SP]
                                stack_pop = 1;
                                mem_read = 1;
                                mem_src = 2'b10;  // SP address
                                reg_write = 1;
                                reg_dist = rb ; 
                                //==>>>Stall For Double memory access [Handle in hazard depending on mem_src]
                                pc_write = 1;
                                pc_src = 3'd0;
                                stack_pop_mux = 0 ;  // Pop to Rb
                                wb_result_mux = 0;
                            end
                            2'b10: begin  // OUT
                                // In top module -> connect rb with output port with enable port_out_write
                                port_out_write = 1; 
                                pc_write = 1;
                                mem_read = 1;
                                pc_src = 3'd0;
                            end
                            2'b11: begin  // IN
                                port_in_read = 1; // Enable of input port
                                reg_dist = rb;
                                reg_write = 1;
                                pc_write = 1;
                                mem_read = 1;
                                pc_src = 3'd0;
                                wb_result_mux = 4;
                            end
                        endcase
                    end
                    UNARY_OP : begin // NOT, NEG, INC, DEC
                        alu_op = ALU_UNARY;
                        dec_ra = 0; 
                        reg_dist = rb;
                        reg_write = 1;
                        pc_write = 1;
                        mem_read = 1;
                        pc_src = 3'd0;
                        wb_result_mux = 3;
                    end
            //  ------------------- B-FORMAT ---------------------- //
                    COND_BRANCHES : begin // JZ & JZ & JC & JV 
                        mem_read = 1 ; 
                        case (brx) 
                            0 : begin  // JZ 
                                pc_write = 1 ;  
                                if (!z_flag) 
                                    pc_src = 0 ;  
                                else begin 
                                    pc_src = 2 ; // PC ← R[rb] 
                                    flush = 1 ;  // ==>> FLSUH due to jump instruction [Handle in integretion]
                                end
                            end
                            1 : begin  // JN 
                                pc_write = 1 ; 
                                if (!n_flag) 
                                    pc_src = 0 ;  
                                else begin 
                                    pc_src = 2 ; // PC ← R[rb]
                                    flush = 1 ;  // ==>> FLSUH due to jump instruction [Handle in integretion]
                                end
                            end
                           2 : begin  // JC 
                                pc_write = 1 ; 
                                if (!c_flag) 
                                    pc_src = 0 ;  
                                else begin 
                                    pc_src = 2 ;    // PC ← R[rb]
                                    flush = 1 ;     // ==>> FLSUH due to jump instruction [Handle in integretion]
                                end
                            end
                            3 : begin  // JV
                                pc_write = 1 ; 
                                if (!v_flag) 
                                    pc_src = 0 ;  
                                else begin 
                                    pc_src = 2 ;     // PC ← R[rb]
                                    flush = 1 ;      // ==>> FLSUH due to jump instruction [Handle in integretion]
                                end
                            end
                        endcase
                    end
                    LOOP : begin        // LOOP ( R[ra]-- ; if(R[ra]≠0) PC←R[rb] )
                        alu_op = ALU_UNARY ;
                        pc_write = 1 ;
                        pc_src = 0 ;
                        mem_read = 1;
                        dec_ra = 1;
                        reg_write = 1 ; 
                        reg_dist = ra ; 
                        is_loop = 1 ; 
                        wb_result_mux = 3;
                        // Stall to wait for condition evaluation in LOOP_DECIDE
                    end
                    JUMP : begin                // JMP & CALL & RET &RTI 
                        case (brx) 
                            0 : begin           //JMP 
                                pc_write = 1 ; 
                                ir_write = 1;
                                mem_read = 1; 
                                pc_src = 2 ;    // PC ← R[rb]
                                flush = 1 ;     //==>> FLUSH due to jump instruction [Handle in integretion]
                            end
                            1 : begin           // CALL  (X[SP--] ← PC + 1; PC ← R[rb]) 
                                stack_push = 1 ; 
                                pc_write = 1 ; 
                                ir_write = 1;
                                mem_read = 1; 
                                pc_src = 2 ;   /// PC ← R[rb]
                                mem_write = 1; 
                                //==>>>Stall For Double memory access [Handle in hazard depending on mem_src]
                                mem_src = 2 ;  // SP source 
                                stack_push_mux = 1 ;  // Push PC+1 into stack (Not Rb )
                            end
                            2 : begin       // RET  (PC ← X[++SP])
                                stack_pop = 1 ;   
                                pc_write = 1; 
                                ir_write = 1;
                                mem_read = 1;
                                stack_pop_mux = 1 ;  // Pop to pc 
                                pc_src = 3 ;  // stack source  
                                flush = 1 ;    //==>> FLUSH due to jump instruction [Handle in integretion]
                            end
                            3 : begin       // RTI  (PC ← X[++SP] ; Flags restored )
                                stack_pop = 1 ;     
                                pc_write = 1; 
                                ir_write = 1;
                                mem_read = 1;
                                stack_pop_mux = 1 ;  // Pop to pc  
                                pc_src = 3 ;  // stack source 
                                flush = 1 ;    //==>> FLSUH due to jump instruction [Handle in integretion]
                                restore_flags = 1 ; 
                            end
                        endcase
                    end
                    // ---------------- L-FORMAT -----------------// 
                    LOAD_STORE : begin         // LDM 
                        case (ra) 
                            0 : begin           // LDM  ( R[rb] ← imm )
                                mem_read = 1 ; 
                                pc_write = 1 ;
                                ir_write = 0; 
                                imm_write = 1; 
                                pc_src = 0 ;  // pc+1
                                reg_write = 1 ; 
                                reg_dist = rb ; 
                                is_two_byte = 1 ; // To swap to FETCH2 state
                                wb_result_mux = 2;
                                /* Here we should consider connecting the immediate register 
                                with the register file input   */
                            end
                            1 : begin           //LDD (R[rb] ← M[ea])
                                mem_read = 1 ;  // ==>>>> remeber to handle two double memory access [Handled in hazard unit ]
                                wb_result_mux = 0;
                                ir_write = 0; 
                                imm_write = 1; 
                                pc_write = 1 ; 
                                pc_src = 0 ;    // pc+1
                                reg_write = 1 ; 
                                reg_dist = rb ;  
                                is_two_byte = 1 ; // To swap to FETCH2 state
                                mem_src = 3 ;   // Immediate register source 
                                /* Here we should consider connecting  the memory with register file
                                and immediate register    */
                            end
                            2 : begin           //STD  ( M[ea] ←R[rb])
                                mem_read = 1 ;  // ==>>>>> dont forget to handle double memory access [Handled in hazard unit ]
                                mem_write = 1 ;   
                                pc_write = 1 ; 
                                ir_write = 0; 
                                imm_write = 1; 
                                pc_src = 0 ;  // pc+1
                                is_two_byte = 1 ; // To swap to FETCH2 state
                                mem_src = 3 ; // Immediate register source 
                                /* Here we should consider connecting  the memory with register file
                                and immediate register    */
                            end
                        endcase
                    end
                        LDI : begin             // LDI (R[rb] ← M[R[ra]])
                                mem_read = 1 ;  // ==>>>>> dontt forget to handle double memory access [Handled in hazard unit ]
                                wb_result_mux = 0;  
                                pc_write = 1 ; 
                                pc_src = 0 ;  // pc+1
                                reg_write = 1 ; 
                                reg_dist = rb ; 
                                mem_src = 1 ; // Register file source (ra)
                                /*  Here we have to consider connecting memory with register file   */
                        end
                        STI : begin            // STI  (M[R[ra]] ←R[rb])
                            mem_read = 1 ; // ==>>>>> dontt forget to handle double memory access [Handled in hazard unit ]   
                            pc_write = 1; 
                            pc_src = 0 ; // pc+1 
                            mem_write = 1 ; 
                            mem_src = 1 ; // Register file source (ra)
                            /*  Here we have to consider connecting memory with register file   */
                        end
                endcase
            end
        endcase
    end
endmodule