`timescale 1ns/1ps
module testbench;
	reg clock_50M;
	reg rst_n;
	reg set;
	reg [9:0] KEY;
	reg Add;
	reg Sub;
	reg Mul;
	reg Div;
	wire [7:0] lcd_data;
	wire [4:0] led;

	initial begin
		clock_50M=1;
		Add=0;
		Sub=0;
		Mul=0;
		Div=0;
		rst_n=1;
		#1000
		rst_n=0;
		#1000
		rst_n=1;
		#1000 
		set=1;
		#1000;
		set=0;
		#1000
		KEY=10'b0000000001;
		#1000
		set=1;
		#500;
		set=0;
		KEY=10'b0000000000;
		#1000;
		Add=1;
		#1000;
		set=1;
		#500
		set=0;
		Add=0;
		#1000;
		KEY=10'b0000100000;
		#1000
		set=1;
		#500
		set=0;
		KEY=10'b0000000000;
		#1000
		set=1;
		#500
		set=0;
	end 

	always #10 clock_50M=~clock_50M;
	textlcd_2 textlcd_2(.rst_n      (rst_n ),
					.clk        (clock_50M),
					.set		(set),
					.KEY        (KEY),
					.Add        (Add),
					.Sub        (Sub),
					.Mul        (Mul),
					.Div        (Div),
					.lcd_rs     (lcd_rs),
					.lcd_rw     (lcd_rw),
					.lcd_en     (lcd_en),
					.lcd_p      (lcd_p),
					.lcd_n      (lcd_n),
					.lcd_data   (lcd_data),
					.led        (led));
endmodule