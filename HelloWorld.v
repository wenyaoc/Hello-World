module HelloWorld (clk, rstn, disp);
	input clk;  // input clock
	input rstn; // reset
	output[6:0] disp; // 7-seg display
	
	reg[6:0] disp;
	reg[2:0] state;
	parameter 	ST_H 	= 	3'd0,
					ST_E 	= 	3'd1,
					ST_L1 = 	3'd2,
					ST_L2 = 	3'd3,
					ST_O 	= 	3'd4;
					
	always@(posedge clk or negedge rstn)
	begin
		if(~rstn)
			begin
				state <= ST_H;
			end
		else
			begin
				case(state)
					ST_H:
					begin
						disp <= 7'b1001000;
						state <= ST_E;
					end
					ST_E:
					begin
						disp <= 7'b0110000;
						state <= ST_L1;
					end
					ST_L1:
					begin
						disp <= 7'b1110001;
						state <= ST_L2;
					end
					ST_L2:
					begin
						disp <= 7'b1110001;
						state <= ST_O;
					end
					ST_O:
					begin
						disp <= 7'b0000001;
						state <= ST_H;
					end
				endcase
			end
	end
endmodule
