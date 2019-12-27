# FPGA实现简易计算器

[TOC]

## 1 总体目标
采用Altera DE2作为开发板，Quartus ii 13.0作为集成开发工具，ModelSim作为仿真工具，LCD显示器作为载体，拨动开关作为输入，实现FPGA版的简易计算器。实现两个四位数的加减乘除。
## 2 版本

| 版本 | 实现功能         | 优点                            | 缺点                                       |
| ---- | ---------------- | ------------------------------- | ------------------------------------------ |
| 1.0  | 一位数的加减乘除 | lcd显示部分思路清晰             | 触发方式单一                               |
| 2.0  | 四位数的加减乘除 | lcd可处理不定位数、触发方式丰富 | 每个always功能不清晰、代码较乱（需要更改） |

## 3 v1.0

### 3.1 输入输出

pin|位宽|功能|方向
:-:|-|:--|-
set|1|确定当前状态的输入结果，转向下一状态|input
clock_50M|1|生成50MHz的时钟信号|input
KEY|9|想被计算的数，会被先后寄存到A、B两个寄存器中。|input
Add|1|加号信号|input
Sub|1|减号信号|input
Mul|1|乘号信号|input
Div|1|除号信号|input
lcd_rs|1|lcd的写入类型信号。高电平：写入数据，低电平：写入指令（对lcd进行配置的参数)|output
lcd_rw|1|lcd的读写信号。高电平：读出，低电平：写入。我们保持低电平，因为只需要往lcd里面写数据即可|output
lcd_en|1|lcd的使能信号。高电平：使能。|output
lcd_p|1|lcd的正极|output
lcd_n|1|lcd的负极|output
lcd_data|8|lcd数据总线，写入的可以是要显示的数据、配置lcd的指令|output
led|1|可将led的亮灭绑定在某个引脚上，可用于调试判断该引脚是否损坏|output

### 3.2 状态机

| State | 状态             | 功能         | 保持原状态条件   | 进入下一状态条件            | 回到初态条件     |
| ----- | ---------------- | ------------ | ---------------- | --------------------------- | ---------------- |
| 5'd0  | Idle             | 静止         | cancel or !rst_n | set                         | cancel or !rst_n |
| 5'd1  | Insert_1stNumber | 插入第一个数 | 其余路径         | A_KEY_REG && !cancel && set | cancel or !rst_n |
| 5'd2  | Insert_OpCode    | 插入符号     | 其余路径         | OP_Done && !cancel && set   | cancel or !rst_n |
| 5'd3  | Insert_2ndNumber | 插入第二个数 | 其余路径         | B_KEY_REG && !cancel && set | cancel or !rst_n |
| 5'd4  | Result_Is        | 计算结果     | 其余路径         | 无                          | cancel or !rst_n |

### 3.3 寄存器

| 计算内容   | 2         | +       | 5         | =     | 7           |
| ---------- | --------- | ------- | --------- | ----- | ----------- |
| 数据寄存器 | A         | OP_Code | B         | 8'h3d | C           |
| 状态寄存器 | A_KEY_REG | OP_Done | B_KEY_REG | 无    | Result_Done |

### 3.4 lcd驱动

#### 3.4.1 显示转码

KEY|value|lcd_data
-|-|-
9'b000000000|0|8'h30
9'b000000001|1|8'h31
9'b000000010|2|8'h32
9'b000000100|3|8'h33
9'b000001000|4|8'h34
9'b000010000|5|8'h35
9'b000100000|6|8'h36
9'b001000000|7|8'h37
9'b010000000|8|8'h38
9'b100000000|9|8'h39
Add|+|8'h2b
Sub|-|8'h2d
Mul|*|8'h2a
Div|/|8'h2f
Equal|=|8'h3d

![1](./1.png)

#### 3.4.2 分频时钟

时钟|频率
-|-
clock_50M|50MHz
lcd_clk_en|500Hz

#### 3.4.3 lcd状态机
向lcd写入数据信号，状态机会在5'd8到5'd19之间循环，动态刷新：

lcd_state|功能|写入内容|lcd_rs|lcd_en|下一状态
-|-|-|-|-|-
5'd0|Mode_Set|8'h31|0|1|+1
5'd1|停半拍|||0|+1
5'd2|Cursor_Set|8'h0c|0|1|+1
5'd3|停半拍|||0|+1
5'd4|Address_Set|8'h06|0|1|+1
5'd5|停半拍|||0|+1
5'd6|Clear_Set|8'h01|0|1|+1
5'd7|停半拍|||0|+1
5'd8|addr|8'h80|0|1|+1
5'd9|停半拍|||0|+1
5'd10|A|ASCII(A)|1|1|+1
5'd11|停半拍|||0|+1
5'd12|Operator|ASCII(OP_Code)|1|1|+1
5'd13|停半拍|||0|+1
5'd14|B|ASCII(B)|1|1|+1
5'd15|停半拍|||0|+1
5'd16|=|8'h3d|1|1|+1
5'd17|停半拍|||0|+1
5'd18|C|ASCII(C)|1|1|+1
5'd19|停半拍|||0|5'd8

### 3.5 源代码

calculator.v

```verilog
`timescale 1ns/1ps

module calculator(
	input clock_50M,
	input rst_n,
	input set,
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
	output [4:0] led);

textlcd_2 textlcd_2(.rst_n(rst_n),
					.clk(clock_50M),
					.set(set),
					.KEY(KEY),
					.Add(Add),.Sub(Sub),.Mul(Mul),.Div(Div),
					.lcd_rs(lcd_rs),
					.lcd_rw(lcd_rw),
					.lcd_en(lcd_en),
					.lcd_p(lcd_p),
					.lcd_n(lcd_n),
					.lcd_data(lcd_data),
					.led(led));
endmodule
```

textlcd_2.v

```verilog
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
```

testbench.v
```verilog
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
```
## 4 v2.0

### 4.1 模块结构

| 模块         | 功能                          |
| ------------ | ----------------------------- |
| calculator.v | 顶层                          |
| textlcd_3.v  | 显示与计算模块                |
| bcdtobin.v   | bcd码（十进制码） -> 二进制码 |
| bintobcd.v   | 二进制码 -> bcd码（十进制码） |
| calc_16x16.v | 加减乘除的计算模块            |

### 4.2 输入输出

|      pin       | 位宽 | 功能                                                         | 方向   |
| :------------: | ---- | :----------------------------------------------------------- | ------ |
|     rst_n      | 1    | 低电平复位                                                   | input  |
|      set       | 1    | 确定当前状态的输入结果，转向下一状态                         | input  |
|     append     | 1    | 确定一位数字                                                 | input  |
|   clock_50M    | 1    | 生成50MHz的时钟信号                                          | input  |
|      KEY       | 10   | 想被计算的数，会被先后寄存到A、B两个寄存器中。               | input  |
|      Add       | 1    | 加号信号                                                     | input  |
|      Sub       | 1    | 减号信号                                                     | input  |
|      Mul       | 1    | 乘号信号                                                     | input  |
|      Div       | 1    | 除号信号                                                     | input  |
|     lcd_rs     | 1    | lcd的写入类型信号。高电平：写入数据，低电平：写入指令（对lcd进行配置的参数) | output |
|     lcd_rw     | 1    | lcd的读写信号。高电平：读出，低电平：写入。我们保持低电平，因为只需要往lcd里面写数据即可 | output |
|     lcd_en     | 1    | lcd的使能信号。高电平：使能。                                | output |
|     lcd_p      | 1    | lcd的正极                                                    | output |
|     lcd_n      | 1    | lcd的负极                                                    | output |
|    lcd_data    | 8    | lcd数据总线，写入的可以是要显示的数据、配置lcd的指令         | output |
|   led_state    | 5    | 状态灯                                                       | output |
|    led_bits    | 4    | 位数灯                                                       | output |
|   led_value    | 8    | 数值灯                                                       | output |
| led_start_bits | 4    | 针对bcd码的起始位灯                                          | output |

### 4.3 状态机

| State | 状态             | 功能         | 进入下一状态条件                              | 回到初态条件 |
| ----- | ---------------- | ------------ | --------------------------------------------- | ------------ |
| 5'd0  | Idle             | 静止         | set                                           | rst_n        |
| 5'd1  | Insert_1stNumber | 插入第一个数 | set && A_bcd <u>（带计算数为0可能有问题）</u> | rst_n        |
| 5'd2  | Insert_OpCode    | 插入符号     | set                                           | rst_n        |
| 5'd3  | Insert_2ndNumber | 插入第二个数 | set && B_bcd <u>（带计算数为0可能有问题）</u> | rst_n        |
| 5'd4  | Result_Is        | 计算结果     | rst_n                                         | rst_n        |

### 4.4 寄存器

| 内容   | 255                                     + | 532                                     = | 887                             |
| ------ | ----------------------------------------- | ----------------------------------------- | ------------------------------- |
| 二进制 | A_bin                                     | B_bin                                     | C_bin                           |
| 内容   | 16'h00ff                                  | 16'h0214                                  | 32'h0000_0377                   |
| 十进制 | A_bcd                                     | B_bcd                                     | C_bcd                           |
| 内容   | 16'b0000_0010_0101_0101                   | 16'b0000_0010_0001_0100                   | {16'd0,16'b0000_1000_1000_0111} |
| 位数   | A_bits                                    | B_bits                                    | C_bits                          |
| 内容   | 3                                         | 3                                         | 3                               |
| 起始位 | A_start_bits                              | B_start_bits                              | C_start_bits                    |
| 内容   | 3->7->11                                  | 3->7->11                                  | 3->7->11                        |

*bcd码用于输入和显示，二进制码用于计算，所以对A和B以**bcd**码输入，转成**bin**码，而对C则是用计算完成的**bin**码，转换成**bcd**码*

### 4.5 lcd驱动

#### 4.5.1 显示转码

| KEY            | value | lcd_data |
| -------------- | ----- | -------- |
| 10'b0000000001 | 0     | 8'h30    |
| 10'b0000000010 | 1     | 8'h31    |
| 10'b0000000100 | 2     | 8'h32    |
| 10'b0000001000 | 3     | 8'h33    |
| 10'b0000010000 | 4     | 8'h34    |
| 10'b0000100000 | 5     | 8'h35    |
| 10'b0001000000 | 6     | 8'h36    |
| 10'b0010000000 | 7     | 8'h37    |
| 10'b0100000000 | 8     | 8'h38    |
| 10'b1000000000 | 9     | 8'h39    |
| Add            | +     | 8'h2b    |
| Sub            | -     | 8'h2d    |
| Mul            | *     | 8'h2a    |
| Div            | /     | 8'h2f    |
| Equal          | =     | 8'h3d    |

![1](./1.png)

#### 4.5.2 分频时钟

| 时钟       | 频率  |
| ---------- | ----- |
| clock_50M  | 50MHz |
| lcd_clk_en | 500Hz |

#### 4.5.3 lcd状态机

向lcd写入数据信号，状态机会在5'd8到5'd19之间循环，动态刷新：

| lcd_state | 功能        | 写入内容       | lcd_rs | lcd_en | 下一状态             |
| --------- | ----------- | -------------- | ------ | ------ | -------------------- |
| 5'd0      | Mode_Set    | 8'h31          | 0      | 1      | +1                   |
| 5'd1      | 停半拍      |                |        | 0      | +1                   |
| 5'd2      | Cursor_Set  | 8'h0c          | 0      | 1      | +1                   |
| 5'd3      | 停半拍      |                |        | 0      | +1                   |
| 5'd4      | Address_Set | 8'h06          | 0      | 1      | +1                   |
| 5'd5      | 停半拍      |                |        | 0      | +1                   |
| 5'd6      | Clear_Set   | 8'h01          | 0      | 1      | +1                   |
| 5'd7      | 停半拍      |                |        | 0      | +1                   |
| 5'd8      | addr        | 8'h80          | 0      | 1      | +1                   |
| 5'd9      | 停半拍      |                |        | 0      | +1                   |
| 5'd10     | A           | ASCII(A)       | 1      | 1      | +1                   |
| 5'd11     | 停半拍      |                |        | 0      | +1 或 -1（A_count)   |
| 5'd12     | Operator    | ASCII(OP_Code) | 1      | 1      | +1                   |
| 5'd13     | 停半拍      |                |        | 0      | +1                   |
| 5'd14     | B           | ASCII(B)       | 1      | 1      | +1                   |
| 5'd15     | 停半拍      |                |        | 0      | +1 或 -1 (B_count)   |
| 5'd16     | =           | 8'h3d          | 1      | 1      | +1                   |
| 5'd17     | 停半拍      |                |        | 0      | +1                   |
| 5'd18     | C           | ASCII(C)       | 1      | 1      | +1                   |
| 5'd19     | 停半拍      |                |        | 0      | 5'd8 或 -1 (C_count) |

### 4.6 源代码

calculator.v

```verilog
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
```

textlcd_3.v

```verilog
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

//配置参数，详见lcd1602技术文档
parameter    Mode_Set    =  8'h31;//8'b0011_0001 Function set
parameter	 Cursor_Set  =  8'h0c;//8'b0000_1010 Display ON/OFF Control
parameter	 Address_Set =  8'h06;//8'b0000_0110 Entry Mode Set
parameter	 Clear_Set   =  8'h01;//8'b0000_0001 Clear Display

//bcd码 转 ASCII码
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

//计算C_bcd的位数
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

//A_bits、B_bits计算，以append作为加一判据
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

//A_bcd、B_bcd输入，以append作为输入一位数字的输入信号，以A_bits或B_bits判断输入哪一位
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

    
//状态机
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

//状态灯的显示
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

//bcd码 转 二进制码
bcdtobin A_bcd2bin(.bcd(A_bcd),
				.clk(clk),
				.bin(A_bin));

//bcd码 转 二进制码
bcdtobin B_bcd2bin(.bcd(B_bcd),
				.clk(clk),
				.bin(B_bin));
    
//计算模块
calc_16x16 calc_16x16(.clk(clk),
					.a(A_bin),
					.b(B_bin),
					.OP_Code(OP_Code),
					.y(C_bin),
					.done(Result_Done));

//二进制码 转 bcd码
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

//A、B、C起始位的计算
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

//lcd显示
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

//lcd分频
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

//lcd状态机
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
```



## 5 仿真过程

ModelSim

### 5.1 准备文件

filelist.v

```verilog
`include "./textlcd_3.v"
`include "./testbench.v"
`include "./calc_16x16.v"
`include "./bcdtobin.v"
`include "./bintobcd.v"
```

sim.do

```shell
quit -sim 
vlib work
vmap work work
vlog ./filelist.v
vsim -novopt work.testbench
```

详见ModelSim命令

testbench.v

```verilog
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
```

### 5.2 开始仿真

#### ①命令行进入源代码目录

![QQ截图20191227145945](.\image\20191227145945.png)

![QQ截图20191227150024]( https://github.com/FanMover/FPGA_calculator/tree/master/image/QQ截图20191227150024.png)

#### ②输入do sim.do开始仿真，编译不通过根据报错信息检查源码

![QQ截图20191227150045](.\image\QQ截图20191227150045.png)

#### ③编译通过后弹出仿真窗口 

![QQ截图20191227150351](.\image\QQ截图20191227150351.png)

#### ④点击左边模块，选择变量添加到波形

![QQ截图20191227150407](.\image\QQ截图20191227150407.png)

![QQ截图20191227150414](.\image\QQ截图20191227150414.png)

![批注 2019-12-27 150917](.\image\批注 2019-12-27 150917.png)

#### ⑤选定仿真时长，run起来

![QQ截图20191227150941](.\image\QQ截图20191227150941.png)

![QQ截图20191227151000](.\image\QQ截图20191227151000.png)

![QQ截图20191227151014](.\image\QQ截图20191227151014.png)

还可以选择光标具体查看某个时刻的信号

## 6 上板过程

Quartus ii 13.0

### 6.1 准备文件

Tcl_script1.tcl

```tcl
set_location_assignment PIN_N2 -to clock_50M

set_location_assignment PIN_N25 -to rst_n         
set_location_assignment PIN_N26 -to set  
set_location_assignment PIN_C13  -to append        
set_location_assignment PIN_AE14 -to Add           
set_location_assignment PIN_AF14 -to Sub          
set_location_assignment PIN_AD13 -to Mul          
set_location_assignment PIN_AC13 -to Div          
#rst_n:SW0
#set:SW1
#append:SW7
#Add:SW3
#Sub:SW4
#Mul:SW5
#Div:SW6      

set_location_assignment PIN_V2 -to KEY[0]         
set_location_assignment PIN_V1 -to KEY[1]         
set_location_assignment PIN_U4 -to KEY[2]          
set_location_assignment PIN_U3 -to KEY[3]          
set_location_assignment PIN_T7 -to KEY[4]         
set_location_assignment PIN_P2 -to KEY[5]         
set_location_assignment PIN_P1 -to KEY[6]         
set_location_assignment PIN_N1 -to KEY[7]          
set_location_assignment PIN_A13 -to KEY[8]
set_location_assignment PIN_B13 -to KEY[9]
# KEY:SW17~SW9,分别表示0~9

set_location_assignment PIN_L4 -to lcd_p
set_location_assignment PIN_K2 -to lcd_n
set_location_assignment PIN_K1 -to lcd_rs
set_location_assignment PIN_K4 -to lcd_rw
set_location_assignment PIN_K3 -to lcd_en
set_location_assignment PIN_J1 -to lcd_data[0]
set_location_assignment PIN_J2 -to lcd_data[1]
set_location_assignment PIN_H1 -to lcd_data[2]
set_location_assignment PIN_H2 -to lcd_data[3]
set_location_assignment PIN_J4 -to lcd_data[4]
set_location_assignment PIN_J3 -to lcd_data[5]
set_location_assignment PIN_H4 -to lcd_data[6]
set_location_assignment PIN_H3 -to lcd_data[7]

set_location_assignment PIN_AE23 -to led_state[0]
set_location_assignment PIN_AF23 -to led_state[1]
set_location_assignment PIN_AB21 -to led_state[2]
set_location_assignment PIN_AC22 -to led_state[3]
set_location_assignment PIN_AD22 -to led_state[4]

set_location_assignment PIN_AD12 -to led_bits[0]
set_location_assignment PIN_AE12 -to led_bits[1]
set_location_assignment PIN_AE13 -to led_bits[2]
set_location_assignment PIN_AF13 -to led_bits[3]

set_location_assignment PIN_AE15 -to led_start_bits[0]
set_location_assignment PIN_AD15 -to led_start_bits[1]
set_location_assignment PIN_AC14 -to led_start_bits[2]
set_location_assignment PIN_AA13 -to led_start_bits[3]

set_location_assignment PIN_AE22 -to led_value[0]
set_location_assignment PIN_AF22 -to led_value[1]
set_location_assignment PIN_W19 -to led_value[2]
set_location_assignment PIN_V18 -to led_value[3]
set_location_assignment PIN_U18 -to led_value[4]
set_location_assignment PIN_U17 -to led_value[5]
set_location_assignment PIN_AA20 -to led_value[6]
set_location_assignment PIN_Y18 -to led_value[7]
```

将calculator.v中的输入输出变量约束在DE2开发板的物理引脚上，详见DE2_UserManual.pdf

### 6.2 开始上板

#### ①运行tcl脚本引脚约束

![QQ截图20191227152042](.\image\QQ截图20191227152042.png)

![QQ截图20191227151603](.\image\QQ截图20191227151603.png)

pin Planner查看引脚

![QQ截图20191227152056](.\image\QQ截图20191227152056.png)

![QQ截图20191227151703](.\image\QQ截图20191227151703.png)

#### ②编译不通过根据报错信息检查源码

![QQ截图20191227151542](.\image\QQ截图20191227151542.png)



![QQ截图20191227151839](.\image\QQ截图20191227151839.png)

![QQ截图20191227151853](.\image\QQ截图20191227151853.png)

#### ③编译通过烧录到板中

![QQ截图20191227151924](.\image\QQ截图20191227151924.png)



### 6.3 上板调试

#### ①打开SignalTap

![QQ截图20191227152027](.\image\QQ截图20191227152027.png)

#### ②设置触发条件和查看信号

![QQ截图20191227152144](.\image\QQ截图20191227152144.png)

#### ③设置采样时钟、采样深度以及触发模式

![QQ截图20191227152305](.\image\QQ截图20191227152305.png)

#### ④保存配置，重新编译

![QQ截图20191227151542](.\image\QQ截图20191227151542.png)

Sample depth不能太大，会超过内存容限

![QQ截图20191227152244](.\image\QQ截图20191227152244.png)

#### ⑤上板，开启触发



![QQ截图20191227152214](.\image\QQ截图20191227152214.png)

![QQ截图20191227152324](.\image\QQ截图20191227152324.png)

![QQ截图20191227152345](.\image\QQ截图20191227152345.png)

![QQ截图20191227152412](.\image\QQ截图20191227152412.png)



由于写文档的时候没有插入板子，图片可能与真实情况有些不同，具体情况软件有提示。