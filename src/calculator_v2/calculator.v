`timescale 1ns/1ps

module calculator(
	input clock_50M,
	input rst_n,
	input set,
	input append,
	input [9:0] KEY,
	input Add,
	input Sub,
	input Mul,
	input Div,
	output lcd_rs,
	output lcd_rw,
	output lcd_en,
	output lcd_p,
	output lcd_n,
	output [7:0] lcd_data,
	output [4:0] led_state,
	output [3:0] led_bits,
	output [7:0] led_value,
	output [3:0] led_start_bits);

textlcd_3 textlcd_3(.rst_n(rst_n),
					.clk(clock_50M),
					.set(set),
					.append(append),
					.KEY(KEY),
					.Add(Add),.Sub(Sub),.Mul(Mul),.Div(Div),
					.lcd_rs(lcd_rs),
					.lcd_rw(lcd_rw),
					.lcd_en(lcd_en),
					.lcd_p(lcd_p),
					.lcd_n(lcd_n),
					.lcd_data(lcd_data),
					.led_state(led_state),
					.led_bits(led_bits),
					.led_value(led_value),
					.led_start_bits(led_start_bits));
endmodule

