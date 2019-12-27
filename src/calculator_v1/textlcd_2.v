`timescale 1ns/1ps

module textlcd_2(
	input rst_n,
	input clk,  //50M
	input set,
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
	output reg [4:0] led);

assign lcd_n = 1'b0;
assign lcd_p = 1'b1;
assign lcd_rw = 1'b0; //只写入lcd，不读出lcd

reg [7:0] A,B,C,OP_Code; 

reg OP_Done, Result_Done, A_KEY_REG,B_KEY_REG;
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

reg [4:0] State;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		State <= Idle;
		OP_Done <= 1'b0;
		A_KEY_REG <= 1'b0;
		B_KEY_REG <= 1'b0;
		Result_Done <= 1'b0;
		A <= 8'd0;
		B <= 8'd0;
		C <= 8'd0;
		OP_Code <= 8'd43;
		Add_reg <= 1'b0;
		Sub_reg <= 1'b0;
		Mul_reg <= 1'b0;
		Div_reg <= 1'b0;
		led <= 5'b00000;
	end
	else begin
		case(State)
			Idle: begin
				led <= 5'b00001;
				if(set) begin State <= Insert_1stNumber; end
				else begin State <= Idle; end
			end

			Insert_1stNumber: begin
				led <= 5'b00010;
				if(KEY[9:0] && !A_KEY_REG && set) begin
					A_KEY_REG <= 1'b1;
					if(KEY[9]) begin A<=8'd9; end
					else if(KEY[8]) begin A<=8'd8; end
					else if(KEY[7]) begin A<=8'd7; end
					else if(KEY[6]) begin A<=8'd6; end
					else if(KEY[5]) begin A<=8'd5; end
					else if(KEY[4]) begin A<=8'd4; end
					else if(KEY[3]) begin A<=8'd3; end
					else if(KEY[2]) begin A<=8'd2; end
					else if(KEY[1]) begin A<=8'd1; end
					else if(KEY[0]) begin A<=8'd0; end
					else begin A<=8'd0; end
				end 
				/**
				for debug
				else if(~KEY[8:0] && A_KEY_REG && !cancel && set) begin
					led <= 5'b10000;
				end
				**/
				else if(~KEY[9:0] && A_KEY_REG && set) begin
					State <= Insert_OpCode;
				end
				else begin
					State <= Insert_1stNumber;
				end
			end

			Insert_OpCode: begin
				led <= 5'b00100;
				if(!OP_Done && set) begin
					if(Add && !OP_Done) begin Add_reg <= 1; OP_Done <= 1; OP_Code <= 8'd43; end
					if(Sub && !OP_Done) begin Sub_reg <= 1; OP_Done <= 1; OP_Code <= 8'd45; end
					if(Mul && !OP_Done) begin Mul_reg <= 1; OP_Done <= 1; OP_Code <= 8'd42; end
					if(Div && !OP_Done) begin Div_reg <= 1; OP_Done <= 1; OP_Code <= 8'd47; end
				end
				else if((Add || Sub || Mul || Div) && OP_Done && set) begin
					State <= Insert_2ndNumber;
				end
				else begin
					State <= Insert_OpCode;
				end
			end

			Insert_2ndNumber: begin
				led <= 5'b01000;
				if(KEY[9:0] && !B_KEY_REG && set) begin
					B_KEY_REG <= 1'b1;
					if(KEY[9]) begin B<=8'd9; end
					else if(KEY[8]) begin B<=8'd8; end
					else if(KEY[7]) begin B<=8'd7; end
					else if(KEY[6]) begin B<=8'd6; end
					else if(KEY[5]) begin B<=8'd5; end
					else if(KEY[4]) begin B<=8'd4; end
					else if(KEY[3]) begin B<=8'd3; end
					else if(KEY[2]) begin B<=8'd2; end
					else if(KEY[1]) begin B<=8'd1; end
					else if(KEY[0]) begin B<=8'd1; end
					else begin B<=8'd0; end
				end 
				else if(~KEY[9:0] && B_KEY_REG && set) begin
					State <= Result_Is;
				end
				else begin
					State <= Insert_2ndNumber;
				end
			end

			Result_Is: begin
				led <= 5'b10000;
				if(!set) begin
					if(Add_reg && !Result_Done) begin C <= A+B; Result_Done <= 1; end
					if(Sub_reg && !Result_Done) begin C <= A-B; Result_Done <= 1; end
					if(Mul_reg && !Result_Done) begin C <= A*B; Result_Done <= 1; end
					if(Div_reg && !Result_Done) begin C <= A/B; Result_Done <= 1; end
				end
				else begin 
					State <= Result_Is;
				end
			end
		endcase
	end
end

reg [31:0] cnt;
reg lcd_clk_en;
always @(posedge clk or negedge rst_n)      
begin 
	if(!rst_n)
		begin
			cnt <= 1'b0;
			lcd_clk_en <= 1'b0;
		end
	//else if(cnt == 32'h24999)  
	else if(cnt==32'h249)
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


wire [7:0] addr;
assign addr = 8'h80;
reg [4:0] lcd_state;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			lcd_state <= 1'b0;
			lcd_rs <= 1'b0;
			lcd_en <= 1'b0;
			lcd_data <= 1'b0;   
		end
	else if(lcd_clk_en) begin
			case(lcd_state)
				//-------------------init_state---------------------
				5'd0: begin                
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_data <= Mode_Set;   
						lcd_state <= lcd_state + 1'd1;
						end
				5'd1: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd2: begin
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_data <= Cursor_Set;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd3: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd4: begin
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_data <= Address_Set;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd5: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd6: begin
						lcd_rs <= 1'b0;
						lcd_en <= 1'b1;
						lcd_data <= Clear_Set;
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
						lcd_data <= addr; 
						lcd_state <= lcd_state + 1'd1;
						end
				5'd9: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd10: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_data <= ASCII(A);   //write data
						lcd_state <= lcd_state + 1'd1;
						 end
				5'd11: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd12: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_data <= ASCII(OP_Code);   //write data
						lcd_state <= lcd_state + 1'd1;
						end
				5'd13: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd14: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_data <= ASCII(B);   //write data
						lcd_state <= lcd_state + 1'd1;
						 end
				5'd15: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end
				5'd16: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_data <= 8'h3d;   //write data
						lcd_state <= lcd_state + 1'd1;
						end
				5'd17: begin
						lcd_en <= 1'b0;
						lcd_state <= lcd_state + 1'd1;
						end    
				5'd18: begin
						lcd_rs <= 1'b1;
						lcd_en <= 1'b1;
						lcd_data <= ASCII(C);   //write data: tens digit
						lcd_state <= lcd_state + 1'd1;
						end
				5'd19: begin
						lcd_en <= 1'b0;
						lcd_state <= 5'd8;
					   end
				default: lcd_state <= 5'bxxxxx;
			endcase
	end
end
endmodule 

