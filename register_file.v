module register_file (
    input clk,rst,write_en,
    input [1:0] read_addr_a, read_addr_b, write_addr,
    input [7:0] write_data,
    output reg [7:0]  read_data_a, read_data_b, 
    output [7:0] sp_value
);

reg [7:0] R[0:3];

always @(posedge clk or posedge rst) begin
    if(rst) begin
        R[0] <= 0;
        R[1] <= 0;
        R[2] <= 0;
        R[3] <= 8'hFF;
    end
    else if (write_en) begin
        R[write_addr] <= write_data;
    end
end

always @(*) begin
    read_data_a = R[read_addr_a];
    read_data_b = R[read_addr_b];
end

assign sp_value = R[3];

endmodule