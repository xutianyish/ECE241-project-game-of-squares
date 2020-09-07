`timescale 1ns / 1ns // `timescale time_unit/time_precision

module se_inputs(
	input clk,
	input	resetn,
	input go,
	
	output [31:0]sound
);
	
	wire enable_address;
	wire [8:0]address;
	
	se_control se_c0(
		.clk(clk),
		.resetn(resetn),
		.go(go),
		.address(address),
		.enable_address(enable_address)	
	);
	
	se_datapath se_d0(
		.clk(clk),
		.resetn(resetn),
		.address(address),
		.enable_address(enable_address),
		.sound(sound)
	);

endmodule

module se_control(
	input clk,
	input resetn,
	input go,
	input [8:0]address,
	
	output reg enable_address	
);
	reg[2:0] current_state;
	reg[2:0] next_state;
	reg [11:0]delay;//depends on sampling frequency
	
	localparam S_RESET = 3'b000,
				  S_PLAY_NOTE = 3'b001,
				  S_WAIT = 3'b010,
				  S_RESET_WAIT = 3'b011;
				  
	always@(*)begin
		case(current_state)
			S_RESET: next_state = go? S_RESET_WAIT: S_RESET;
			S_RESET_WAIT: next_state = go? S_RESET_WAIT:S_PLAY_NOTE; 
			S_PLAY_NOTE: next_state = (address == 9'd429)?S_RESET:S_WAIT;
			S_WAIT: next_state = (delay < 12'd2080)? S_WAIT:S_PLAY_NOTE;
			default: next_state = S_RESET;
		endcase
	end
	
	always@(posedge clk)begin
		if(!resetn)
			current_state <= S_RESET;
		else
			current_state <= next_state;
	end
	
	
	reg reset_delay;
	reg enable_delay;
	//counts @ 24KHz
	always@(posedge clk)begin
		if(!resetn)
			delay <= 12'b0;
		else if(reset_delay)
			delay <= 12'b0;
		else if(enable_delay)
			delay <= delay + 1'b1;
	end
	
	always@(*)begin
		enable_address = 1'b0;
		reset_delay = 1'b0;
		enable_delay = 1'b0;
		
		case(current_state)
			S_PLAY_NOTE: begin
								 reset_delay = 1'b1;
								 enable_address = 1'b1;
							 end
			S_WAIT: enable_delay = 1'b1;
		endcase
	end
	
	
endmodule


module se_datapath(
	input clk,
	input resetn,
	input enable_address,
	output [31:0]sound,
	output reg[8:0]address
);
	
	
	always@(posedge clk)begin
		if(!resetn)
			address <= 9'b0;
		else begin
			if(address == 9'd430)
				address <= 9'b0;
			else if(enable_address)
				address <= address + 1'b1;
		end
	end
	
	wire [31:0]snd;
	//memory block, snd is the data in each sample
	SE_move SE_sample(
		.address(address),
		.clock(clk),
		.data(32'b0),
		.wren(1'b0),
		.q(snd)
	);
	
	assign sound = (snd-32'd10000)*32'd12000;

	

endmodule
