`timescale 1ns/1ps
module testbench;
	reg clock_50M;
	reg rst_n;
	reg append;
	reg set;
	reg [9:0] KEY;
	reg Add;
	reg Sub;
	reg Mul;
	reg Div;
	wire lcd_rs;
	wire lcd_rw;
	wire lcd_p;
	wire lcd_n;
	wire lcd_en;
	wire [7:0] lcd_data;
	wire [4:0] led_state;
	wire [3:0] led_bits;
	wire [7:0] led_value;
	wire [3:0] led_start_bits;

	initial begin
		clock_50M=1;
		Add=0;
		Sub=0;
		Mul=0;
		Div=0;
		KEY='b0000000000;
		rst_n=1;
		#1000
		rst_n=0;
		#1000
		rst_n=1;
		#1000
		set=1;
		#1000
		set=0;
		//insert 1st Number
		#1000
		KEY=10'b0000000100;
		#1000
		append=1;
		#1000;
		append=0;
		#1000
		KEY=10'b0000001000;
		#1000
		append=1;
		#1000;
		append=0;
		#1000
		set=1;
		#1000
		set=0;
		#1000;
		KEY=10'b0000000000;
		#1000
		//insert Operator
		Add=1;
		#1000;
		set=1;
		#1000
		set=0;
		Add=0;
		//insert 2nd Number
		#1000
		KEY=10'b0000000100;
		#1000
		append=1;
		#1000;
		append=0;
		#1000
		KEY=10'b0000001000;
		#1000
		append=1;
		#1000;
		append=0;
		#1000
		set=1;
		#1000
		set=0;
		#1000
		KEY=10'b0000000000;
		//show Result
		#1000
		set=1;
		#500
		set=0;
	end 

	always #10 clock_50M=~clock_50M;

	textlcd_3 textlcd(.rst_n      (rst_n ),
					.clk        (clock_50M),
					.set		(set),
					.append		(append),
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
					.led_state  (led_state),
					.led_bits	(led_bits),
					.led_value	(led_value),
					.led_start_bits(led_start_bits));
endmodule