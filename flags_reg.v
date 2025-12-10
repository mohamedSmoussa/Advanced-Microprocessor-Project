module flags_reg (
    input clk,rst,update_flags,z_in,n_in,c_in,v_in,setc,clrc,restore_flags,
    input [3:0] restore_flags_value,
    output z_flag,n_flag,v_flag,c_flag,
    output [3:0] flags_out
);
reg [3:0] CCR;
always @(posedge clk, posedge rst) begin
    if(rst)
        CCR <= 0;
    else if(restore_flags)
        CCR <= restore_flags_value;
    else if(setc)
        CCR[2] <= 1;
    else if(clrc)
        CCR[2] <= 0;
    else if(update_flags) begin
        CCR[0] <= z_in;
        CCR[1] <= n_in;
        CCR[2] <= c_in;
        CCR[3] <= v_in;
    end
end
assign flags_out = CCR;
assign z_flag = CCR[0];
assign n_flag = CCR[1];
assign c_flag = CCR[2];
assign v_flag = CCR[3];
endmodule 