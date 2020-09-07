`timescale 1ns / 1ns // `timescale time_unit/time_precision

module bgm_inputs(
	input clk,
	input	resetn,
	input go,	
	output [31:0]sound
);
	
	wire enable_address;
	
	bgm_control bgm_c0(
		.clk(clk),
		.resetn(resetn),
		.go(go),
		.enable_address(enable_address)	
	);
	
	bgm_datapath bgm_d0(
		.clk(clk),
		.resetn(resetn),
		.enable_address(enable_address),
		.sound(sound)
	);

endmodule

module bgm_control(
	input clk,
	input resetn,
	input go,
	
	output reg enable_address	
);
	reg[2:0] current_state;
	reg[2:0] next_state;
	reg [14:0]delay;//depends on sampling frequency
	
	localparam S_RESET = 3'b000,
				  S_PLAY_NOTE = 3'b001,
				  S_WAIT = 3'b010;
				  
	always@(*)begin
		case(current_state)
			S_RESET: next_state = go? S_PLAY_NOTE: S_RESET;
			S_PLAY_NOTE: next_state = S_WAIT;
			S_WAIT: next_state = (delay < 15'd20801)? S_WAIT:S_PLAY_NOTE;
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
			delay <= 15'b0;
		else if(reset_delay)
			delay <= 15'b0;
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


module bgm_datapath(
	input clk,
	input resetn,
	input enable_address,
	output [31:0]sound
);
	
	reg[17:0] address;
	
	always@(posedge clk)begin
		if(!resetn) begin
			address <= 18'b0;
		end
		
		else begin
			if(address == 18'd105599)
				address <= 18'b0;
			else if(enable_address)
				address <= address + 1'b1;
		end
	end
	
	wire [31:0]bgm2_snd;
	
	
	//memory block, snd is the data in each sample
	bgm2 bgm2_b0(
		.address(address),
		.clock(clk),
		.data(32'b0),
		.wren(1'b0),
		.q(bgm2_snd)
	);
	
	assign sound = (bgm2_snd - 32'd10000)*32'd10000;

endmodule
