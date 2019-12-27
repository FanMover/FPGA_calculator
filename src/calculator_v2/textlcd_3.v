`timescale 1ns/1ps

module textlcd_3(
	input rst_n,
	input clk,  //50M
	input set,
	input append,
	input [9:0] KEY,
	input Add,
	input Sub,
	input Mul,
	input Div,
	output reg lcd_rs,
	output wire lcd_rw,
	output reg lcd_en,
	output wire lcd_p,
	output wire lcd_n,
	output reg [7:0] lcd_data,
	output reg [4:0] led_state,
	output reg [3:0] led_bits,
	output wire [7:0] led_value,
	output reg [3:0] led_start_bits);

assign lcd_n = 1'b0;
assign lcd_p = 1'b1;
assign lcd_rw = 1'b0; //只写入lcd，不读出lcd

reg [15:0] A_bcd, B_bcd;
wire [15:0] A_bin, B_bin;
wire [31:0] C_bcd;
wire [31:0] C_bin;

reg [7:0] OP_Code;
reg OP_Done;
wire Result_Done, Decode_Done;
reg Add_reg, Sub_reg, Mul_reg, Div_reg;

parameter Idle = 5'd0;
parameter Insert_1stNumber = 5'd1;
parameter Insert_OpCode = 5'd2;
parameter Insert_2ndNumber = 5'd3;
parameter Result_Is = 5'd4;

parameter    Mode_Set    =  8'h31;//8'b0011_0001 Function set:interface data length 8 bits,1-line,5x8 dots
parameter	 Cursor_Set  =  8'h0c;//8'b0000_1010 Display ON/OFF Control:set display(x), set cursor(闁blinking of cursor(闁
parameter	 Address_Set =  8'h06;//8'b0000_0110 Entry Mode Set:moving direction(闁shift of entire display(x)
parameter	 Clear_Set   =  8'h01;//8'b0000_0001 Clear Display

function [7:0] ASCII;
	input [7:0] data;
	case(data)
		8'd0:ASCII=8'h30;
		8'd1:ASCII=8'h31;
		8'd2:ASCII=8'h32;
		8'd3:ASCII=8'h33;
		8'd4:ASCII=8'h34;
		8'd5:ASCII=8'h35;
		8'd6:ASCII=8'h36;
		8'd7:ASCII=8'h37;
		8'd8:ASCII=8'h38;
		8'd9:ASCII=8'h39;
		8'd43:ASCII=8'h2b;//+
		8'd45:ASCII=8'h2d;//-
		8'd42:ASCII=8'h2a;//*
		8'd47:ASCII=8'h2f;//'\'
		default:begin ASCII=8'h00; end 
	endcase
endfunction	

function [3:0] getBits;
	input [31:0] C_bcd;
	if(C_bcd & 32'hf000_0000) begin getBits = 4'd8; end
	else if(C_bcd & 32'h0f00_0000) begin getBits = 4'd7; end
	else if(C_bcd & 32'h00f0_0000) begin getBits = 4'd6; end
	else if(C_bcd & 32'h000f_0000) begin getBits = 4'd5; end
	else if(C_bcd & 32'h0000_f000) begin getBits = 4'd4; end
	else if(C_bcd & 32'h0000_0f00) begin getBits = 4'd3; end
	else if(C_bcd & 32'h0000_00f0) begin getBits = 4'd2; end
	else if(C_bcd & 32'h0000_000f) begin getBits = 4'd1; end
	else begin getBits = 4'd0; end
endfunction

reg [4:0] State;
assign led_value = A_bin[7:0];
reg [3:0] A_bits = 4'd0;
reg [3:0] B_bits = 4'd0;
wire [3:0] C_bits = getBits(C_bcd);


always @(posedge append or negedge rst_n) begin
	if(!rst_n) begin
		A_bits <= 4'd0;
		B_bits <= 4'd0;
	end
	else begin
		case(State) 
			Idle: begin end
			Insert_1stNumber: begin A_bits <= A_bits + 4'd1; led_bits <= A_bits + 'd1; end
			Insert_OpCode: begin end
			Insert_2ndNumber: begin B_bits <= B_bits + 4'd1; led_bits <= B_bits + 'd1; end
			Result_Is: begin end
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		A_bcd <= 16'd0;
		B_bcd <= 16'd0;
	end
	else if(append) begin
		case(State) 
			Idle: begin end
			Insert_1stNumber: begin
				case(A_bits) 
					4'd0: begin end
					4'd1: begin  
						case(KEY)
							10'b0000_0000_01: begin A_bcd[3 :0] <= 4'd0; end 
							10'b0000_0000_10: begin A_bcd[3 :0] <= 4'd1; end 
							10'b0000_0001_00: begin A_bcd[3 :0] <= 4'd2; end 
							10'b0000_0010_00: begin A_bcd[3 :0] <= 4'd3; end 
							10'b0000_0100_00: begin A_bcd[3 :0] <= 4'd4; end 
							10'b0000_1000_00: begin A_bcd[3 :0] <= 4'd5; end 
							10'b0001_0000_00: begin A_bcd[3 :0] <= 4'd6; end 
							10'b0010_0000_00: begin A_bcd[3 :0] <= 4'd7; end 
							10'b0100_0000_00: begin A_bcd[3 :0] <= 4'd8; end 
							10'b1000_0000_00: begin A_bcd[3 :0] <= 4'd9; end 
						endcase
					end
					4'd2: begin
						case(KEY)
							10'b0000_0000_01: begin A_bcd[7 :4] <= 4'd0; end 
							10'b0000_0000_10: begin A_bcd[7 :4] <= 4'd1; end 
							10'b0000_0001_00: begin A_bcd[7 :4] <= 4'd2; end 
							10'b0000_0010_00: begin A_bcd[7 :4] <= 4'd3; end 
							10'b0000_0100_00: begin A_bcd[7 :4] <= 4'd4; end 
							10'b0000_1000_00: begin A_bcd[7 :4] <= 4'd5; end 
							10'b0001_0000_00: begin A_bcd[7 :4] <= 4'd6; end 
							10'b0010_0000_00: begin A_bcd[7 :4] <= 4'd7; end 
							10'b0100_0000_00: begin A_bcd[7 :4] <= 4'd8; end 
							10'b1000_0000_00: begin A_bcd[7 :4] <= 4'd9; end 
						endcase
					end
					4'd3: begin
						case(KEY)
							10'b0000_0000_01: begin A_bcd[11 :8] <= 4'd0; end 
							10'b0000_0000_10: begin A_bcd[11 :8] <= 4'd1; end 
							10'b0000_0001_00: begin A_bcd[11 :8] <= 4'd2; end 
							10'b0000_0010_00: begin A_bcd[11 :8] <= 4'd3; end 
							10'b0000_0100_00: begin A_bcd[11 :8] <= 4'd4; end 
							10'b0000_1000_00: begin A_bcd[11 :8] <= 4'd5; end 
							10'b0001_0000_00: begin A_bcd[11 :8] <= 4'd6; end 
							10'b0010_0000_00: begin A_bcd[11 :8] <= 4'd7; end 
							10'b0100_0000_00: begin A_bcd[11 :8] <= 4'd8; end 
							10'b1000_0000_00: begin A_bcd[11 :8] <= 4'd9; end 
						endcase
					end
					4'd4: begin
						case(KEY)
							10'b0000_0000_01: begin A_bcd[15 :12] <= 4'd0; end 
							10'b0000_0000_10: begin A_bcd[15 :12] <= 4'd1; end 
							10'b0000_0001_00: begin A_bcd[15 :12] <= 4'd2; end 
							10'b0000_0010_00: begin A_bcd[15 :12] <= 4'd3; end 
							10'b0000_0100_00: begin A_bcd[15 :12] <= 4'd4; end 
							10'b0000_1000_00: begin A_bcd[15 :12] <= 4'd5; end 
							10'b0001_0000_00: begin A_bcd[15 :12] <= 4'd6; end 
							10'b0010_0000_00: begin A_bcd[15 :12] <= 4'd7; end 
							10'b0100_0000_00: begin A_bcd[15 :12] <= 4'd8; end 
							10'b1000_0000_00: begin A_bcd[15 :12] <= 4'd9; end 
						endcase
					end
				endcase
			end
			Insert_OpCode: begin end
			Insert_2ndNumber: begin
				case(B_bits) 
					4'd0: begin end
					4'd1: begin  
						case(KEY)
							10'b0000_0000_01: begin B_bcd[3 :0] <= 4'd0; end 
							10'b0000_0000_10: begin B_bcd[3 :0] <= 4'd1; end 
							10'b0000_0001_00: begin B_bcd[3 :0] <= 4'd2; end 
							10'b0000_0010_00: begin B_bcd[3 :0] <= 4'd3; end 
							10'b0000_0100_00: begin B_bcd[3 :0] <= 4'd4; end 
							10'b0000_1000_00: begin B_bcd[3 :0] <= 4'd5; end 
							10'b0001_0000_00: begin B_bcd[3 :0] <= 4'd6; end 
							10'b0010_0000_00: begin B_bcd[3 :0] <= 4'd7; end 
							10'b0100_0000_00: begin B_bcd[3 :0] <= 4'd8; end 
							10'b1000_0000_00: begin B_bcd[3 :0] <= 4'd9; end 
						endcase
					end
					4'd2: begin
						case(KEY)
							10'b0000_0000_01: begin B_bcd[7 :4] <= 4'd0; end 
							10'b0000_0000_10: begin B_bcd[7 :4] <= 4'd1; end 
							10'b0000_0001_00: begin B_bcd[7 :4] <= 4'd2; end 
							10'b0000_0010_00: begin B_bcd[7 :4] <= 4'd3; end 
							10'b0000_0100_00: begin B_bcd[7 :4] <= 4'd4; end 
							10'b0000_1000_00: begin B_bcd[7 :4] <= 4'd5; end 
							10'b0001_0000_00: begin B_bcd[7 :4] <= 4'd6; end 
							10'b0010_0000_00: begin B_bcd[7 :4] <= 4'd7; end 
							10'b0100_0000_00: begin B_bcd[7 :4] <= 4'd8; end 
							10'b1000_0000_00: begin B_bcd[7 :4] <= 4'd9; end 
						endcase
					end
					4'd3: begin
						case(KEY)
							10'b0000_0000_01: begin B_bcd[11 :8] <= 4'd0; end 
							10'b0000_0000_10: begin B_bcd[11 :8] <= 4'd1; end 
							10'b0000_0001_00: begin B_bcd[11 :8] <= 4'd2; end 
							10'b0000_0010_00: begin B_bcd[11 :8] <= 4'd3; end 
							10'b0000_0100_00: begin B_bcd[11 :8] <= 4'd4; end 
							10'b0000_1000_00: begin B_bcd[11 :8] <= 4'd5; end 
							10'b0001_0000_00: begin B_bcd[11 :8] <= 4'd6; end 
							10'b0010_0000_00: begin B_bcd[11 :8] <= 4'd7; end 
							10'b0100_0000_00: begin B_bcd[11 :8] <= 4'd8; end 
							10'b1000_0000_00: begin B_bcd[11 :8] <= 4'd9; end 
						endcase
					end
					4'd4: begin
						case(KEY)
							10'b0000_0000_01: begin B_bcd[15 :12] <= 4'd0; end 
							10'b0000_0000_10: begin B_bcd[15 :12] <= 4'd1; end 
							10'b0000_0001_00: begin B_bcd[15 :12] <= 4'd2; end 
							10'b0000_0010_00: begin B_bcd[15 :12] <= 4'd3; end 
							10'b0000_0100_00: begin B_bcd[15 :12] <= 4'd4; end 
							10'b0000_1000_00: begin B_bcd[15 :12] <= 4'd5; end 
							10'b0001_0000_00: begin B_bcd[15 :12] <= 4'd6; end 
							10'b0010_0000_00: begin B_bcd[15 :12] <= 4'd7; end 
							10'b0100_0000_00: begin B_bcd[15 :12] <= 4'd8; end 
							10'b1000_0000_00: begin B_bcd[15 :12] <= 4'd9; end 
						endcase
					end
				endcase
			end
			Result_Is: begin end
		endcase
	end
	else begin end
end

always @(posedge set or negedge rst_n) begin
	if(!rst_n) begin
		OP_Code <= 8'd43;
		OP_Done <= 1'b0;
		Add_reg <= 1'b0;
		Sub_reg <= 1'b0;
		Mul_reg <= 1'b0;
		Div_reg <= 1'b0;
		State <= Idle;
	end
	else begin
		case(State) 

			Idle: begin 
				State <= Insert_1stNumber;
			end

			Insert_1stNumber: begin 
				if(A_bcd) begin State <= Insert_OpCode; end
				else begin State <= Insert_1stNumber; end
			end

			Insert_OpCode: begin 
				if(Add) begin Add_reg <= 1; OP_Done <= 1; OP_Code <= 8'd43; end
				if(Sub) begin Sub_reg <= 1; OP_Done <= 1; OP_Code <= 8'd45; end
				if(Mul) begin Mul_reg <= 1; OP_Done <= 1; OP_Code <= 8'd42; end
				if(Div) begin Div_reg <= 1; OP_Done <= 1; OP_Code <= 8'd47; end
				State <= Insert_2ndNumber;
			end

			Insert_2ndNumber: begin
				if(B_bcd) begin State <= Result_Is; end
				else begin State <= Insert_2ndNumber; end
				
	    	end

			Result_Is: begin 
				State <= Result_Is;
			end
		endcase // State
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		led_state <= 5'b00000;
	end
	else begin
		case(State)

			Idle: begin
				led_state <= 5'b00001;
			end

			Insert_1stNumber: begin
				led_state <= 5'b00010;
			end

			Insert_OpCode: begin
				led_state <= 5'b00100;
			end

			Insert_2ndNumber: begin
				led_state <= 5'b01000;
			end

			Result_Is: begin
				led_state <= 5'b10000;
			end
		endcase
	end
end

bcdtobin A_bcd2bin(.bcd(A_bcd),
				.clk(clk),
				.bin(A_bin));

bcdtobin B_bcd2bin(.bcd(B_bcd),
				.clk(clk),
				.bin(B_bin));

calc_16x16 calc_16x16(.clk(clk),
					.a(A_bin),
					.b(B_bin),
					.OP_Code(OP_Code),
					.y(C_bin),
					.done(Result_Done));

bintobcd bin2bcd(.bin_in (C_bin),
			.clk    (clk),
			.rst_n    (rst_n),
			.dec_out(C_bcd),
			.done   (Decode_Done));

reg [31:0] cnt;
reg lcd_clk_en;


wire [7:0] addr;
assign addr = 8'h80;
reg [4:0] lcd_state;
reg [3:0] A_count = 4'd0;
reg [3:0] B_count = 4'd0;
reg [3:0] C_count = 4'd0;

reg [7:0] A_start_bits = 8'd0;
reg [7:0] B_start_bits = 8'd0;
reg [7:0] C_start_bits = 8'd0;

always @(A_count or B_count or C_count) begin
	if(lcd_state == 5'd10 || lcd_state == 5'd11) begin
		A_start_bits <= 4*A_count - 1;
	end
	else if(lcd_state == 5'd14 || lcd_state == 5'd15) begin
		B_start_bits <= 4*B_count - 1;
	end
	else if(lcd_state == 5'd18 || lcd_state == 5'd19) begin
		C_start_bits <= 4*C_count - 1;
	end
	else begin end
end

always @(A_start_bits or B_start_bits or C_start_bits or lcd_en) begin
	case(lcd_state - 'd1) 
		5'd0: begin lcd_data <= Mode_Set;  end
		5'd1: begin end
		5'd2: begin lcd_data <= Cursor_Set; end
		5'd3: begin end
		5'd4: begin lcd_data <= Address_Set; end
		5'd5: begin end
		5'd6: begin lcd_data <= Clear_Set; end
		5'd7: begin end
		5'd8: begin lcd_data <= addr; end
		5'd9: begin end
		5'd10:begin lcd_data <= ASCII({4'd0,A_bcd[A_start_bits -: 4]}); end
		5'd11:begin end
		5'd12:begin lcd_data <= ASCII(OP_Code); end
		5'd13:begin end
		5'd14:begin lcd_data <= ASCII({4'd0,B_bcd[B_start_bits -: 4]}); end
		5'd15:begin end
		5'd16:begin lcd_data <= 8'h3d; end
		5'd17:begin end
		5'd18:begin lcd_data <= ASCII({4'd0,C_bcd[C_start_bits -: 4]}); end
		5'd19:begin end
	endcase
end

always @(posedge clk or negedge rst_n)      
begin 
	if(!rst_n)
		begin
			cnt <= 1'b0;
			lcd_clk_en <= 1'b0;
		end
	//else if(cnt == 32'h24999)  
	else if(cnt==32'h49999)
		begin
			lcd_clk_en <= 1'b1;
			cnt <= 1'b0;
		end
	else
		begin
			cnt <= cnt + 1'b1;
			lcd_clk_en <= 1'b0;
		end
end 

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			lcd_state <= 1'b0;
			lcd_rs <= 1'b0;
			lcd_en <= 1'b0;
		end
	else if(lcd_clk_en) begin
			case(lcd_state)
				//-------------------init_state---------------------
				5'd0: begin                
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd1: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd2: begin
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd3: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd4: begin
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd5: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd6: begin
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd7: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
						
				//--------------------work state--------------------
				5'd8: begin              
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						A_count <= A_bits + 'd1;
						B_count <= B_bits + 'd1;
						C_count <= C_bits + 'd1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd9: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd10: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						A_count <= A_count - 4'd1;
						lcd_state <= lcd_state + 1'd1; 
						end
				5'd11: begin
						lcd_en <= 1'b0;
						if(!(A_count - 'd1)) begin
							lcd_state <= lcd_state + 1'd1;
						end
						else begin
							lcd_state <= lcd_state - 1'd1;						
						end
						end
				5'd12: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd13: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd14: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						B_count <= B_count - 4'd1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd15: begin
						lcd_en <= 1'b0;
						if(!(B_count - 'd1)) begin
							lcd_state <= lcd_state + 1'd1;
						end
						else begin
							lcd_state <= lcd_state - 1'd1;						
						end
						end
				5'd16: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd17: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end    
				5'd18: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						C_count <= C_count - 4'd1;
						lcd_state <= lcd_state + 1'd1;  
						end
				5'd19: begin
						lcd_en <= 1'b0;
						if(!(C_count - 'd1)) begin
							lcd_state <= 5'd7;
						end
						else begin
							lcd_state <= lcd_state - 1'd1;						
						end
					   end
				default: lcd_state <= 5'bxxxxx;
			endcase
	end
end
endmodule 

