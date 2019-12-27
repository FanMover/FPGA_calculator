module bintobcd
    #(parameter BWIDTH = 32, //must avoid overflow
      parameter DWIDTH  = 32 //must be multiple of 4
     )
    (
    input wire [BWIDTH-1:0] bin_in,
    input wire clk,
    input wire rst_n,
    output reg [DWIDTH-1:0] dec_out,
    output wire done
    );
    
reg [BWIDTH-1:0] bin;
reg [DWIDTH-1:0] bcd;
reg [2:0] state;
reg [7:0] i; //correct if BWIDTH>16
assign done = (state == 3'd1) && !i && dec_out;

localparam RESET = 3'd0;
localparam START = 3'd1;
localparam SHIFT = 3'd2;
localparam ADD	 = 3'd3;
localparam DONE  = 3'd4;

always @ (posedge clk or negedge rst_n)
	if (!rst_n)
		state <= RESET;
	else
	begin
	state <= START;
	case (state)
		RESET:
			begin
			bin <= 'd0;
			i <= 'd0;
			bcd <= 'd0;
			dec_out <= 'd0;
			end
		START:
			begin
			bin <= bin_in;
			bcd <= 'd0;
			state <= SHIFT;
			end
		SHIFT:
			begin
			bin <= {bin [BWIDTH-2:0], 1'd0};
      		bcd <= {bcd [DWIDTH-2:0], bin[BWIDTH-1]};
      		i <= i + 8'd1;
		    if (i == 8'd31)//must be BWIDTH-1
		        state <= DONE;
			    else
			    state <= ADD;
			end
		ADD:
		//comment or uncomment if needed
		//ones
		    begin
			if (bcd[3:0] > 'd4)
				begin
				bcd[3:0] <= bcd[3:0] + 4'd3;
				state <= SHIFT;
				end
			else
				state <= SHIFT;
		    //decs
		    if (bcd[7:4] > 'd4)
				begin
				bcd[7:4] <= bcd[7:4] + 4'd3;
				state <= SHIFT;
				end
			else
				state <= SHIFT;
		    //hundreds
			if (bcd[11:8] > 'd4)
				begin
				bcd[11:8] <= bcd[11:8] + 4'd3;
				state <= SHIFT;
				end
			else
				state <= SHIFT;
		//thousands
		    if (bcd[15:12] > 'd4)
				begin
				bcd[15:12] <= bcd[15:12] + 4'd3;
				state <= SHIFT;
				end
			else
				state <= SHIFT;
	    //...
		    if (bcd[19:16] > 'd4)
					begin
					bcd[19:16] <= bcd[19:16] + 4'd3;
					state <= SHIFT;
					end
				else
					state <= SHIFT;
		//...
		    if (bcd[23:20] > 'd4)
					begin
					bcd[23:20] <= bcd[23:20] + 4'd3;
					state <= SHIFT;
					end
				else
					state <= SHIFT; 
	    //...
		    if (bcd[27:24] > 'd4)
					begin
					bcd[27:24] <= bcd[27:24] + 4'd3;
					state <= SHIFT;
					end
				else
					state <= SHIFT; 
	    //...
		    if (bcd[31:28] > 'd4)
					begin
					bcd[31:28] <= bcd[31:28] + 4'd3;
					state <= SHIFT;
					end
				else
					state <= SHIFT;
			    end
		DONE:
			begin
			dec_out <= bcd;
			i <= 8'd0;
			state <= START;
			end
		default:
			state <= RESET;
		endcase
	end
	
endmodule
