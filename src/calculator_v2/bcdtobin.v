module bcdtobin
	(
	input wire [15:0] bcd,
	input wire clk,
	output reg [15:0] bin);

reg [15:0] bcd_reg;

always @(bcd or bin or clk) begin
	bcd_reg <= bcd;
	bin <= bcd[3:0] + bcd[7:4]*'d10 + bcd[11:8]*'d100 + bcd[15:12]*'d1000;
end
endmodule