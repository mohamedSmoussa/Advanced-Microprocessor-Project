module alu (input signed [7:0] operand_a, operand_b,
    input [3:0] alu_op,
    input [1:0] ra_field,
    input c_in, dec_ra,
    input old_c_flag, old_v_flag, old_z_flag, old_n_flag,
    output reg signed  [7:0] result,
    output reg z_flag_alu_out,n_flag_alu_out,c_flag_alu_out,v_flag_alu_out,flags_update
); 
reg [8:0] temp_result;
always@(*) begin
    c_flag_alu_out = old_c_flag;
    v_flag_alu_out = old_v_flag;
    z_flag_alu_out = old_z_flag;
    n_flag_alu_out = old_n_flag;
    flags_update = 0;
    case(alu_op) 
        1: begin 
            result = operand_b;
            flags_update = 0;
        end
        2: begin
            temp_result = {1'b0,operand_a} + {1'b0,operand_b};
            if (temp_result[8])
                c_flag_alu_out = 1;
            else c_flag_alu_out = 0;
            if(temp_result[7:0] == 0)
                z_flag_alu_out = 1;
            else z_flag_alu_out = 0;
            if (temp_result[7] == 1)
                n_flag_alu_out = 1;
            else n_flag_alu_out = 0;
            result = temp_result[7:0];
            if ((operand_a[7] == operand_b[7]) && (operand_a[7] != result[7]))
                v_flag_alu_out = 1;
            else v_flag_alu_out = 0;
            flags_update = 1;
        end 
        3: begin
            temp_result = {1'b0,operand_a} - {1'b0,operand_b};
            if (temp_result[8])
                c_flag_alu_out = 0;
            else c_flag_alu_out = 1;
            if(temp_result[7:0] == 0)
                z_flag_alu_out = 1;
            else z_flag_alu_out = 0;
            if (temp_result[7] == 1)
                n_flag_alu_out = 1;
            else n_flag_alu_out = 0;
            result = temp_result[7:0];
            if ((operand_a[7] ^ operand_b[7]) && (result[7] ^ operand_a[7]))
                v_flag_alu_out = 1;
            else v_flag_alu_out = 0;
            flags_update = 1;
        end
        4: begin
            result = operand_a & operand_b;
            if(result[7:0] == 0)
                z_flag_alu_out = 1;
            else z_flag_alu_out = 0;
            if (result[7] == 1)
                n_flag_alu_out = 1;
            else n_flag_alu_out = 0;
            flags_update = 1;
        end
        5: begin
            result = operand_a | operand_b;
            if(result[7:0] == 0)
                z_flag_alu_out = 1;
            else z_flag_alu_out = 0;
            if (result[7] == 1)
                n_flag_alu_out = 1;
            else n_flag_alu_out = 0;
            flags_update = 1;
        end
        6: begin
            case (ra_field)
                0: begin
                    result = {operand_b[6:0],c_in};
                    c_flag_alu_out = operand_b[7];
                    v_flag_alu_out = operand_b[7] ^ result[7];
                    if(result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                end
                1: begin
                    result = {c_in,operand_b[7:1]};
                    c_flag_alu_out = operand_b[0];
                    v_flag_alu_out = operand_b[7] ^ result[7];
                    if(result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                end
                2: c_flag_alu_out = 1;
                3: c_flag_alu_out = 0;
            endcase
            flags_update = 1;
        end
        8: begin
            if(dec_ra) begin
                temp_result = {1'b0,operand_a} - 1;
                    if (temp_result[8])
                        c_flag_alu_out = 0;
                    else c_flag_alu_out = 1;
                    if(temp_result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (temp_result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                    if (operand_a == 8'b1000_0000)  
                        v_flag_alu_out = 1;                 
                    else v_flag_alu_out = 0;
                    result = temp_result[7:0];
            end
            else case (ra_field)
                0: begin
                    result = ~(operand_b);
                    if(result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                end
                1: begin
                    result = ~(operand_b) + 1;
                    if(result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                end
                2: begin 
                    temp_result = {1'b0,operand_b} + 1;
                    if (temp_result[8])
                        c_flag_alu_out = 1;
                    else c_flag_alu_out = 0;
                    if(temp_result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (temp_result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                    if (operand_b == 8'b0111_1111)
                        v_flag_alu_out = 1;                 
                    else v_flag_alu_out = 0;
                    result = temp_result[7:0];
                end 
                3:  begin 
                    temp_result = {1'b0,operand_b} - 1;
                    if (temp_result[8])
                        c_flag_alu_out = 0;
                    else c_flag_alu_out = 1;
                    if(temp_result[7:0] == 0)
                        z_flag_alu_out = 1;
                    else z_flag_alu_out = 0;
                    if (temp_result[7] == 1)
                        n_flag_alu_out = 1;
                    else n_flag_alu_out = 0;
                    if (operand_b == 8'b1000_0000)  
                        v_flag_alu_out = 1;                 
                    else v_flag_alu_out = 0;
                    result = temp_result[7:0];
                end 
            endcase
            flags_update = 1; 
        end
        default: begin
            flags_update = 0;
        end
    endcase
end
endmodule
