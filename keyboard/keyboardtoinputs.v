
//module that converts keyboard data code to left, right, up, down and enter signals
module data_to_inputs(
	input [7:0] last_data_received,
	input [7:0] prior_to_last_data_received,
	output reg left, right, up, down, enter 
);

	always@(*)begin
		if(last_data_received == 8'h1D && prior_to_last_data_received != 8'hF0)begin
			up = 1'b1;
			left = 1'b0;
			right = 1'b0;
			down = 1'b0;
			enter = 1'b0;
		end
		else if(last_data_received == 8'h1B && prior_to_last_data_received != 8'hF0)begin
			down = 1'b1;
			left = 1'b0;
			right = 1'b0;
			up = 1'b0;
			enter = 1'b0;
		end
		else if(last_data_received == 8'h1C && prior_to_last_data_received != 8'hF0)begin
			left = 1'b1;
			right = 1'b0;
			up = 1'b0;
			down = 1'b0;
			enter = 1'b0;
		end
		else if(last_data_received == 8'h23 && prior_to_last_data_received != 8'hF0)begin
			right = 1'b1;
			left = 1'b0;
			up = 1'b0;
			down = 1'b0;
			enter = 1'b0;
		end
		else if(last_data_received == 8'h5A && prior_to_last_data_received != 8'hF0)begin
			left = 1'b0;
			right = 1'b0;
			up = 1'b0;
			down = 1'b0;
			enter = 1'b1;
		end
		else begin
			left = 1'b0;
			right = 1'b0;
			up = 1'b0;
			down = 1'b0;
			enter = 1'b0;
		end		
	end

endmodule





