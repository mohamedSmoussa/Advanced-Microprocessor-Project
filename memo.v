module memory_stack (
    input wire clk,                          // System clock (sync writes
    input wire rst,                          // Reset (no mem clear; use .mem for init; SP=255 external)
    input wire mem_en,                       // Memory enable (from CU, active in MEM stage)
    input wire mem_read,                     // Read control (from CU; combo out)
    input wire mem_write,                    // Write control (from CU; sync write)
    
    input wire port_sel,                     // 1=I/O ports (IN/OUT), 0=memory/stack (from CU)
    input wire [7:0] mem_addr,               // Base address [7:0] (PC/ea from EX/Fetch)
    input wire [7:0] mem_data_in,            // Write data [7:0] (R[rb]/imm/PC/flags from datapath
    input wire [3:0] stack_ctrl,             // Stack op [3:0] from CU: 0000=none, 0001=PUSH, 0010=POP,
                                             // 0011=CALL (push PC+1), 0100=RET (pop PC), 0101=RTI (pop PC+flags),
                                             // 0110=INTR_push (push PC+flags seq), 0111=INTR_flags (2nd push for flags)
    input wire [7:0] sp,                 // Current SP [7:0] from RegFile (R3)
    input wire stack_push,
    input wire stack_pop,
    input wire [7:0] pc,                 // PC [7:0] for CALL/INTR push (from Fetch/PC unit)
    input wire [3:0] ccr_in,                 // CCR flags [3:0] (V=3,C=2,N=1,Z=0) for RTI/INTR push (from Flags)
    input wire [7:0] in_port,                // External IN_PORT [7:0] (top-level input)
    output reg [7:0] sp_out,
    output reg [7:0] mem_data_out,           // Read data [7:0] (to RegFile/PC mux in WB/EX)
    output reg [7:0] out_port,               // OUT_PORT [7:0] (top-level output, latched)
    output reg [3:0] ccr_out                 // Restored CCR [3:0] for RTI (to Flags Unit)
    output reg  [7:0]  imm_ea; 
    output reg  [7:0]  instr;    
);


parameter MEM_WIDTH = 8 ;
parameter MEM_DEPTH = 256;
integer i;
    
reg [MEM_WIDTH-1:0] mem [0:MEM_DEPTH-1];

// Effective address mux 
//stack ptr or mem_addr(indirect and direct using a mux to determine  )
wire [7:0] ea;



initial begin
    $readmemh("data_mem&stack.mem", mem);  
end


assign ea = mem_addr;  

always @(posedge clk) begin
if(pc >= 0 && pc <= 155 )begin
    instr <= mem[pc];
    imm_ea <= mem[pc + 8'd1]; //will be needed in L format 
end 
end



// Synchronous write logic (posedge clk)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        out_port <= 8'h00;   
        ccr_out <= 4'b0000;  
        mem_data_out <= 8'h00;
        for (i=0;i<256;i=i+1) begin
                mem[i]=8'h00;
        end

    end 

    else if (mem_en) begin
        if (mem_write) begin
                
                case (stack_ctrl)
                    4'b0001: begin  
                    // (A format) PUSH: X[SP] <- R[rb]; (SP-- external)
                        mem[sp] <= mem_data_in;
                        if(stack_push)begin 
                            if(sp!=200) begin
                            sp_out <= sp-1;
                            end
                            else begin 
                                sp_out<=sp;
                            end
                        end
                    end

                    //subroutine call 
                    4'b0011: begin  // (B format) CALL: X[SP] <- PC + 1; brx=1 (SP-- external)
                        mem[sp] <= pc + 8'd1;
                        if(stack_push)begin 
                            if(sp!=200) begin
                            sp_out <= sp-1;
                            end
                            else begin 
                                sp_out<=sp;
                            end
                        end
                    end

                    // for interrupt saving pc then saving flags 
                    4'b0110: begin  // INTR: Push PC+1 to X[SP]; (SP-- external; next cycle push flags if 0111)
                        mem[sp] <= pc + 8'd1;
                        if(stack_push)begin 
                            if(sp!=200) begin
                            sp_out <= sp-1;
                            end
                            else begin 
                                sp_out<=sp;
                            end
                        end
                    end
                    4'b0111: begin  // INTR flags push
                    // imp note while saving the flags we dont update the sp it stays pointing on flags 
                        mem[sp] <= {4'h0, ccr_in};  // High 0, low: V C N Z
                    end

                    //default case to store  in memo
                    default: begin
                        if(ea >= 156 && ea <= 199)  begin//MEMO handling STD/STI INSTRUCTION write: M[ea] <- R[rb]
                        mem[ea] <= mem_data_in;
                    end
                    end
                endcase
            
        end
    end
end

// Combinational read logic for forwarding
always @(*) begin
    
    if(mem_en)begin

    if(mem_read) begin

        case (stack_ctrl)
            4'b0010: begin 
            // (A format) POP: (SP++ external first); R[rb] <- X[SP]
                mem_data_out = mem[sp+1];
                if(stack_pop)begin 
                sp_out=sp+1;
                end
            end

            4'b0100: begin  
            //(B format) RET: (SP++ external); PC <- X[SP]
                mem_data_out = mem[sp+1]; //will be muxed later 
                if(stack_pop)begin 
                if(sp!=255)begin 
                sp_out=sp+1;
                end
                else begin 
                    sp_out=sp;
                end
                end
            end

            4'b0101: begin  //(B format) RTI: (SP++ external twice? Seq: pop PC, then pop flags)
                            // Assume CU sequences: First pop PC (data_out=mem[old_sp+1]), then flags from mem[old_sp]
                            // Here: For RTI, read PC from sp (post first ++), flags from mem[sp -1] 
                mem_data_out = mem[sp+1];  // after inc sp it will point on PC due to no updating sp after storing flags 
                ccr_out = mem[sp][3:0];  // Restore V C N Z from prev stack slot
                if(stack_pop)begin 
                if(sp!=255)begin 
                sp_out=sp+1;
                end
                else begin 
                    sp_out=sp;
                end
                end
            end
            //deafult case to load in memo 
            default: begin 
                if(ea >= 156 && ea <= 199) begin // LDD/LDI: mem_data_out <- M[ea]
                mem_data_out = mem[ea];
                end
            end
        endcase
    
    
end
end
end



endmodule



/*brainstorm :

addr mux to choose he address if it is direct or indirect 
as to take it from the instruction or value of reg 

memodatain also mux for which data in will be stored 



read is combi

when we store flags for interrupt handling , sp not updated 
thats why we only inc once 


mem_data_out also should be a mux to choose if iam going to load
in pc or reg 


sp_out should be connected to reg file 


handling stack pointer inc and dec and check for boundries 
sack from 255 > 200
*/
