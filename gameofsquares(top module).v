`timescale 1ns / 1ns // `timescale time_unit/time_precision

module gameofsquares(
		CLOCK_50,					//	On Board 50 MHz
		SW,
		KEY,
		LEDR,
		
		//VGA
		VGA_CLK,   					//	VGA Clock
		VGA_HS,						//	VGA H_SYNC
		VGA_VS,						//	VGA V_SYNC
		VGA_BLANK_N,				//	VGA BLANK
		VGA_SYNC_N,					//	VGA SYNC
		VGA_R,   					//	VGA Red[9:0]
		VGA_G,	 					//	VGA Green[9:0]
		VGA_B,   					//	VGA Blue[9:0]
		
		//PS2 controller
		PS2_CLK,					
		PS2_DAT,
		
		//Audio controller
		AUD_ADCDAT,
		//Biodirections
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,
		FPGA_I2C_SDAT,
		//outputs
		AUD_XCK,
		AUD_DACDAT,

		FPGA_I2C_SCLK,		
);

		//declare inputs and outputs
		input CLOCK_50;						//	On Board 50 MHz
		input [9:0]SW;
		input [3:0]KEY;
		
		inout PS2_CLK;								//ps2 controller
		inout PS2_DAT;								//ps2 controller
		
		output VGA_CLK;   						//	VGA Clock
		output VGA_HS;								//	VGA H_SYNC
		output VGA_VS;								//	VGA V_SYNC
		output VGA_BLANK_N;						//	VGA BLANK
		output VGA_SYNC_N;						//	VGA SYNC
		output [9:0]VGA_R;   					//	VGA Red[9:0]
		output [9:0]VGA_G;	 					//	VGA Green[9:0]
		output [9:0]VGA_B;   					//	VGA Blue[9:0]
		output [9:0]LEDR;
		
		//Audio_controller
		input				AUD_ADCDAT;
		
		inout				AUD_BCLK;
		inout				AUD_ADCLRCK;
		inout				AUD_DACLRCK;
		inout				FPGA_I2C_SDAT;

		output				AUD_XCK;
		output				AUD_DACDAT;
		output				FPGA_I2C_SCLK;
		
		
		
		wire resetn;
		wire up, down, left, right;
		wire enter;
		wire [2:0]colour;
		wire [7:0]x;
		wire [6:0]y;
		wire writeEn;
		assign resetn = KEY[0];
		
//////////////////////////////////////////////
		//audio_contoller
		// Internal Wires
		wire				audio_in_available;
		wire		[31:0]	left_channel_audio_in;
		wire		[31:0]	right_channel_audio_in;
		wire				read_audio_in;

		wire				audio_out_allowed;
		wire		[31:0]	left_channel_audio_out;
		wire		[31:0]	right_channel_audio_out;
		wire				write_audio_out;

		wire [31:0] sound;
		wire [31:0] SE;

		bgm_inputs bgm_in(
			.clk(CLOCK_50),
			.resetn(KEY[0]),
			.go(~KEY[1]),
			.sound(sound)
		);
		
		se_inputs se_in(
		.clk(CLOCK_50),
		.resetn(KEY[0]),
		.go(up||down||left||right||enter),
		.sound(SE)
		);
				
		assign read_audio_in			= audio_in_available & audio_out_allowed;

		assign left_channel_audio_out	= left_channel_audio_in+sound+SE;
		assign right_channel_audio_out	= right_channel_audio_in+sound+SE;
		assign write_audio_out			= audio_in_available & audio_out_allowed;
				
				
		Audio_Controller A0(
			// Inputs
			.CLOCK_50						(CLOCK_50),
			.reset						(~KEY[0]),

			.clear_audio_in_memory		(),
			.read_audio_in				(read_audio_in),
			
			.clear_audio_out_memory		(),
			.left_channel_audio_out		(left_channel_audio_out),
			.right_channel_audio_out	(right_channel_audio_out),
			.write_audio_out			(write_audio_out),

			.AUD_ADCDAT					(AUD_ADCDAT),

			// Bidirectionals
			.AUD_BCLK					(AUD_BCLK),
			.AUD_ADCLRCK				(AUD_ADCLRCK),
			.AUD_DACLRCK				(AUD_DACLRCK),


			// Outputs
			.audio_in_available			(audio_in_available),
			.left_channel_audio_in		(left_channel_audio_in),
			.right_channel_audio_in		(right_channel_audio_in),

			.audio_out_allowed			(audio_out_allowed),

			.AUD_XCK					(AUD_XCK),
			.AUD_DACDAT					(AUD_DACDAT)

		);

		avconf #(.USE_MIC_INPUT(1)) avc (
			.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
			.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
			.CLOCK_50					(CLOCK_50),
			.reset						(~KEY[0])
		);

//////////////////////////////////////////////
		//internal connections of ps2 keyboard
		wire		[7:0]	ps2_key_data;
		wire				ps2_key_pressed;
		
		// Internal Registers of ps2 keyboard
		reg			[7:0]	last_data_received;
		reg   		[7:0] prior_to_last_data_received;
		
		always @(posedge CLOCK_50) begin
			if (KEY[0] == 1'b0)begin
				last_data_received <= 8'h00;
				prior_to_last_data_received <= 8'h00;
			end
			else if (ps2_key_pressed == 1'b1) begin
				prior_to_last_data_received <= last_data_received;
				last_data_received <= ps2_key_data;	
			end	
		end
		
		//convert ps/2 inputs to l/r/u/d/enter
		data_to_inputs d0 (
			.last_data_received(last_data_received),
			.prior_to_last_data_received(prior_to_last_data_received),
			.left(left), 
			.right(right), 
			.up(up), 
			.down(down), 
			.enter(enter) 
		);
		
		PS2_Controller PS2 (
			// Inputs
			.CLOCK_50				(CLOCK_50),
			.reset				(~KEY[0]),

			// Bidirectionals
			.PS2_CLK			(PS2_CLK),
			.PS2_DAT			(PS2_DAT),

			// Outputs
			.received_data		(ps2_key_data),
			.received_data_en	(ps2_key_pressed)
		);

////////////////////////////////////////////		
		//VGA adapter
		vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";	
		
		//inputs to VGA adapter
		vgainputs v0(
			.clk(CLOCK_50),
			.resetn(resetn),
			.up(up),
			.down(down), 
			.left(left), 
			.right(right),
			.enter(enter),
			.x_out(x),
			.y_out(y),
			.colour_out(colour),
			.plot(writeEn),
			.current_state(LEDR[4:0])
		);
		
		
endmodule








