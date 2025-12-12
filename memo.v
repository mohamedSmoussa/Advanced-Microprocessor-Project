module memory_stack (
    input wire clk,                          // System clock (sync writes
    input wire rst,                          // Reset (no mem clear; use .mem for init; SP=255 external)
    input wire mem_en,                       // Memory enable (from CU, active in MEM stage)
    input wire mem_read,                     // Read control (from CU; combo out)
    input wire mem_write,                    // Write control (from CU; sync write)
    
    input wire [7:0] mem_addr,               // Base address [7:0] (PC/ea from EX/Fetch)
    input wire [7:0] mem_data_in,            // Write data [7:0] (R[rb]/imm/PC/flags from datapath
    

    input wire [3:0] ccr_in,                 // CCR flags [3:0] (V=3,C=2,N=1,Z=0) for RTI/INTR push (from Flags)
    input wire save_flags,
    input wire restore_flags,

    output reg [7:0] sp_out,
    output reg [7:0] mem_data_out,           // Read data [7:0] (to RegFile/PC mux in WB/EX)
    output reg [3:0] ccr_out ,                // Restored CCR [3:0] for RTI (to Flags Unit)
    output reg  [7:0]  imm_ea
     
);


parameter MEM_WIDTH = 8 ;
parameter MEM_DEPTH = 256;
integer i;


reg [MEM_WIDTH-1:0] mem [0:MEM_DEPTH-1];




//first part in memo for instr 
//ROM
// added mux to select which address will be passed 
//here the address =pc 

always @(posedge clk) begin
    //boundries of the instr memo 
if(mem_addr >= 0 && mem_addr <= 155 )begin
    if(mem_read)begin 
    mem_data_out <= mem[mem_addr];
    imm_ea <= mem[mem_addr + 8'd1]; //will be needed in L format 
end 
end
end


//second part of memo for data and stack 
//read and write memo 
// Synchronous write logic (posedge clk)
always @(posedge clk or posedge rst) begin
if (rst) begin  
ccr_out <= 4'b0000;  
mem_data_out <= 8'h00;
//reset all data and stack 
for (i=156;i<256;i=i+1) begin
        mem[i]=8'h00;
end

end 

else if (mem_en) begin
if (mem_write) begin
// (A format) PUSH: X[SP] <- R[rb]; (SP-- external)
// (B format) CALL: X[SP] <- PC + 1; brx=1 (SP-- external)
// for interrupt saving pc then saving flags 
// INTR: Push PC+1 to X[SP]; (SP-- external; next cycle push flags if 0111)
//sp bet 255 -> 200 intialized at reg file =255
//mux of add ,addr = sp 
//mem datain is muxed : data from reg - pc - pc+1
if(mem_addr >= 200 && mem_addr <= 255)begin
mem[mem_addr] <= mem_data_in;

    if(mem_addr > 200 && mem_addr <= 255) begin
        sp_out <= mem_addr-1;
    end
    //due to stack overflow ,acheived the limit of stack
    else if (mem_addr == 200 )begin 
        sp_out<=mem_addr;
    end

    // INTR flags push
    // imp note while saving the flags we dont update the sp it stays pointing on flags 
    if(save_flags)begin
    mem[mem_addr-1] <= {4'h0, ccr_in};  // High 0, low: V C N Z
    end

end
//MEMO handling STD/STI INSTRUCTION write: M[ea] <- R[rb]
//mux for data in = reg 
//mux for addr = ea L format 
if(mem_addr >= 156 && mem_addr <= 199)  begin
        mem[mem_addr] <= mem_data_in;
        end       
end
end
end

// Combinational read logic for forwarding
always @(*) begin

if(mem_en)begin

if(mem_read) begin


    if(mem_addr >= 200 && mem_addr <= 255) begin
    // (A format) POP: (SP++ external first); R[rb] <- X[SP]
    //(B format) RET: (SP++ external); PC <- X[SP]
    //(B format) RTI: (SP++ external Seq: pop PC, then pop flags 
        
    //here also using addr mux addr = sp 
    //must be inc first as it points on empty place but in case of storing flags it points on flags 
    //addr = sp
    //dataout = pc or reg 
    mem_data_out = mem[mem_addr+1];
    if(mem_addr >= 200 && mem_addr < 255) begin
    sp_out=mem_addr+1;
    end
    //acheived also the limit of stack 
    else if (mem_addr==255)begin 
    sp_out=mem_addr;
    end
    
    if(restore_flags)begin
    ccr_out = mem[mem_addr][3:0]; 
    end
    end
// LDD/LDI: mem_data_out <- M[ea]
    if(mem_addr >= 156 && mem_addr <= 199) begin 
    mem_data_out = mem[mem_addr];
    end

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
