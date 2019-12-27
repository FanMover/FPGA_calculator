`timescale 1ns/1ps

module calc_16x16(
	input clk,
	input [15:0] a,
	input [15:0] b,
	input [7:0] OP_Code,
	output reg [31:0] y,
	output reg done);

reg [15:0] areg;
reg [15:0] breg;

always @ (clk or a or b) begin
	case(OP_Code) 
		8'd43: begin areg <= a; breg <= b; y <= areg + breg; done <= 1; end
		8'd45: begin areg <= a; breg <= b; y <= areg - breg; done <= 1; end
		8'd42: begin areg <= a; breg <= b; y <= areg * breg; done <= 1; end
		8'd47: begin areg <= a; breg <= b; y <= areg / breg; done <= 1; end
	endcase
end
endmodule
