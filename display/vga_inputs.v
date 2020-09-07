
module vgainputs(
	input clk,
	input resetn,
	input up, down, left, right,
	input enter,
	
	output [7:0]x_out,
	output [6:0]y_out,
	output [2:0]colour_out,
	output plot,
	output [4:0]current_state
);
	
	wire initialize; 
	wire draw_cursor, ld_new_cursor_pos, ld_old_cursor_pos;
	wire ld_board_colour, change_adjacent, update_board;
	wire erase_cursor;
	wire end_display;
	wire start_display;
	wire instruction_display;
	wire [9:0]cursor_counter;
	wire [12:0]board_counter;
	wire [8:0]curr_board_colour;
	wire [14:0]initial_counter;
	
	control c0(
		.clk(clk),
		.resetn(resetn),
		.enter(enter),
		.up(up), 
		.down(down), 
		.left(left), 
		.right(right),
		.cursor_counter(cursor_counter),
		.board_counter(board_counter),
		.initial_counter(initial_counter),
		.curr_board_colour(curr_board_colour),
		.plot(plot),
		.initialize(initialize),
		.draw_cursor(draw_cursor),
		.ld_new_cursor_pos(ld_new_cursor_pos),
		.erase_cursor(erase_cursor),
		.ld_old_cursor_pos(ld_old_cursor_pos),
		.ld_board_colour(ld_board_colour),
		.change_adjacent(change_adjacent),
		.update_board(update_board),
		.end_display(end_display),
		.start_display(start_display),
		.current_state(current_state),
		.instruction_display(instruction_display)
	);
	
	datapath d0(
		.clk(clk),
		.resetn(resetn),
		.initialize(initialize),
		.draw_cursor(draw_cursor),
		.ld_new_cursor_pos(ld_new_cursor_pos), 
		.ld_old_cursor_pos(ld_old_cursor_pos),
		.left(left), 
		.right(right), 
		.up(up), 
		.down(down),
		.ld_board_colour(ld_board_colour),
		.change_adjacent(change_adjacent),
		.update_board(update_board),
		.erase_cursor(erase_cursor),
		.cursor_counter(cursor_counter),
		.board_counter(board_counter),
		.initial_counter(initial_counter),
		.curr_board_colour(curr_board_colour),
		.x_out(x_out),
		.y_out(y_out),
		.colour_out(colour_out),
		.end_display(end_display),
		.start_display(start_display),
		.instruction_display(instruction_display)
	);


endmodule


module control(
	input clk,
	input resetn,
	input enter,
	input up, down, left, right,
	input [9:0]cursor_counter,
	input [12:0]board_counter,
	input [8:0]curr_board_colour,
	input [14:0]initial_counter,
	
	output reg plot,
	output reg initialize,
	output reg draw_cursor,
	output reg ld_new_cursor_pos,
	output reg erase_cursor,
	output reg ld_old_cursor_pos,
	output reg ld_board_colour,
	output reg change_adjacent,
	output reg update_board,
	output reg end_display,
	output reg start_display,
	output reg instruction_display,
	output reg [4:0]current_state
);
	
	reg [4:0]next_state;
	reg [25:0]delaycounter;
	
	
	localparam S_START = 5'd0,
			     S_START_WAIT = 5'd1,
				  S_INITIALIZE = 5'd2,
				  S_DRAW_CURSOR = 5'd3,
				  S_LOAD_POS = 5'd4,
				  S_LOAD_POS_WAIT = 5'd5,
				  S_CHANGE_CURSOR_WAIT = 5'd6,
				  S_ERASE_CURSOR = 5'd7,
				  S_CHANGE_COLOUR = 5'd8,
				  S_CHANGE_ADJACENT = 5'd9,
				  S_WAIT = 5'd10,
				  S_UPDATE_BOARD = 5'd11,
				  S_WAIT_FOR_END = 5'd12,
				  S_END = 5'd13,
				  S_START_DISPLAY = 5'd14,
				  S_START_DISPLAY_WAIT = 5'd15,
				  S_END_WAIT = 5'd16,
				  S_INSTRUCTION = 5'd17,
				  S_INSTRUCTION_WAIT = 5'd18;
				  
	//state table
	always@(*)begin
		case(current_state)
			S_START: next_state = enter? S_START_WAIT:S_START;
			S_START_WAIT: next_state = enter? S_START_WAIT: S_START_DISPLAY;
			S_START_DISPLAY: next_state = enter?S_START_DISPLAY_WAIT:S_START_DISPLAY;
			S_START_DISPLAY_WAIT:next_state = enter?S_START_DISPLAY_WAIT: S_INSTRUCTION;
			S_INSTRUCTION: next_state = enter?S_INSTRUCTION_WAIT:S_INSTRUCTION;
			S_INSTRUCTION_WAIT: next_state = enter? S_INSTRUCTION_WAIT:S_INITIALIZE;
			S_INITIALIZE: next_state = (initial_counter < 15'd19199)? S_INITIALIZE: S_DRAW_CURSOR;//initial_counter < 15'd19199
			S_DRAW_CURSOR: next_state = (cursor_counter < 10'd899)? S_DRAW_CURSOR: S_LOAD_POS; //cursor_counter < 10'd899
			S_LOAD_POS: begin	
							if(enter)
								next_state = S_LOAD_POS_WAIT;
							else if(left || right || up || down)
								next_state = S_CHANGE_CURSOR_WAIT;
							else
								next_state = S_LOAD_POS;
							end
			S_CHANGE_CURSOR_WAIT: next_state = (!left && !right && !up && !down)? S_ERASE_CURSOR:S_CHANGE_CURSOR_WAIT;
		   S_LOAD_POS_WAIT: next_state = enter? S_LOAD_POS_WAIT: S_CHANGE_COLOUR;
			S_ERASE_CURSOR: next_state = (cursor_counter < 10'd899)? S_ERASE_CURSOR:S_DRAW_CURSOR;//cursor_counter < 10'd899
			S_CHANGE_COLOUR: next_state = S_CHANGE_ADJACENT;
			S_CHANGE_ADJACENT: next_state = S_WAIT;
			S_WAIT: next_state = S_UPDATE_BOARD;
			S_UPDATE_BOARD: begin
								 if(board_counter < 13'd8099) //board_counter < 13'd8099
									next_state = S_UPDATE_BOARD;
								 else if(curr_board_colour == 9'b111111111)
									next_state = S_WAIT_FOR_END;
								 else
									next_state = S_DRAW_CURSOR;
								 end
			S_WAIT_FOR_END: next_state = (delaycounter == 26'd50000000)?S_END:S_WAIT_FOR_END;//50000000
			S_END: next_state = (enter)? S_END_WAIT:S_END;
			S_END_WAIT: next_state = (enter)?S_END_WAIT: S_START_DISPLAY;
			default: next_state = S_START_DISPLAY;
		endcase
	end
	
	
	reg reset_delaycounter;
	reg enable_delaycounter;
	//delaycounter
	always@(posedge clk)begin
		if(!resetn)
			delaycounter <= 26'b0;
		else if(reset_delaycounter)
			delaycounter <= 26'b0;
		else if(enable_delaycounter)
			delaycounter <= delaycounter + 1;
	end
	
	//state FFS
	always@(posedge clk)begin
		if(!resetn)
			current_state <= S_START;
		else
			current_state <= next_state;
	end
	
	//output logic
	always@(*)begin
		//by default initialize all signals to zero
		plot = 1'b0;
		initialize = 1'b0;
		draw_cursor = 1'b0;
		ld_new_cursor_pos = 1'b0;
		erase_cursor = 1'b0;
		ld_old_cursor_pos = 1'b0;
		ld_board_colour = 1'b0;
		change_adjacent = 1'b0;
		update_board = 1'b0;
		reset_delaycounter = 1'b0;
		enable_delaycounter = 1'b0;
		end_display = 1'b0;
		start_display = 1'b0;
		instruction_display = 1'b0;
		
		case(current_state)
			S_START_DISPLAY: begin
										plot = 1'b1;
										start_display = 1'b1;
								  end
			S_INSTRUCTION: begin
										plot = 1'b1;
										instruction_display = 1'b1;
								end
			S_INITIALIZE: begin
								  plot = 1'b1;
								  initialize = 1'b1;
							  end
		   S_DRAW_CURSOR: begin
									draw_cursor = 1'b1;
									plot = 1'b1;
									ld_old_cursor_pos = 1'b1;
								end
		   S_LOAD_POS: begin
									ld_new_cursor_pos = 1'b1;
							end
		   S_ERASE_CURSOR: begin
									 erase_cursor = 1'b1;
									 plot = 1'b1;
								 end			
		   S_CHANGE_COLOUR: ld_board_colour = 1'b1;
		   S_CHANGE_ADJACENT: change_adjacent = 1'b1; 
		   S_UPDATE_BOARD: begin
									plot = 1'b1;
									update_board = 1'b1;
								 end
			S_WAIT_FOR_END: begin
									enable_delaycounter = 1'b1;
								 end
			S_END: begin
						reset_delaycounter = 1'b1;
						end_display = 1'b1;
						plot = 1'b1;
					 end
		endcase
	end
				  


endmodule

module datapath(
	input clk,
	input resetn,
	input initialize,
	input draw_cursor,
	input ld_new_cursor_pos, ld_old_cursor_pos,
	input left, right, up, down,
	input ld_board_colour,
	input change_adjacent,
	input update_board,
	input erase_cursor,
	input end_display,
	input start_display,
	input instruction_display,
	
	output reg [9:0]cursor_counter,
	output reg [12:0]board_counter,
	output reg [8:0]curr_board_colour,
	output reg [14:0]initial_counter,
	output reg [7:0]x_out,
	output reg [6:0]y_out,
	output reg [2:0]colour_out
);
		
	
	//counters that sweep through the entire board + background at initialization state
	reg [7:0]x_initial;
	reg [6:0]y_initial;	
	always@(posedge clk)begin
		if(!resetn)begin
			x_initial <= 8'b0;
			y_initial <= 7'b0;
			initial_counter <= 15'b0;
		end
		else begin
		
			if(initialize || end_display || start_display || instruction_display)begin
				x_initial <= x_initial + 1;
				initial_counter <= initial_counter + 1;
				
				if(x_initial == 8'd159 && y_initial == 7'd119)begin
					x_initial <= 8'b0;
					y_initial <= 7'b0;
				end
				
				else if(x_initial == 8'd159)begin
					x_initial <= 8'b0;
					y_initial <= y_initial + 1;
				end

				if(initial_counter == 15'd19199)
					initial_counter <= 15'b0;
			end
			
			else begin
				x_initial <= 8'b0;
				y_initial <= 7'b0;
				initial_counter <= 15'b0;
			end
		end	
	end
	
	wire [2:0]end_colour;
	wire [2:0]start_colour;
	reg [14:0]ram_address;
	wire [2:0]instruction_colour;

	always@(posedge clk)begin
		if(!resetn)begin
			ram_address = 15'b0;
		end
		
		else if(end_display || start_display || instruction_display)begin
				ram_address <= ram_address + 1;
			if(ram_address == 15'd19199)
				ram_address <= 15'b0;
		end
		else
				ram_address <= 15'b0;
	end
	
	//end_display
		ram19200x3 r0(
			.address(ram_address),
			.clock(clk),
			.data(3'b000),
			.wren(1'b0),
			.q(end_colour)
		);
		
	//start_display
		start_ram19200x3 r1(
			.address(ram_address),
			.clock(clk),
			.data(3'b000),
			.wren(1'b0),
			.q(start_colour)
		);
	//instruction
		instruction i0(
			.address(ram_address),
			.clock(clk),
			.data(3'b000),
			.wren(1'b0),
			.q(instruction_colour)
		);
	
	//counters that sweep through the entire board
	reg [6:0]x_board;
	reg [6:0]y_board;
	always@(posedge clk)begin
		if(!resetn)begin
			x_board <= 7'd35;
			y_board <= 7'd15;
			board_counter <= 13'b0;
		end
		else begin
			if(update_board)begin
				y_board <= y_board + 1;
				board_counter <= board_counter + 1;
				
				if(y_board == 7'd104 && x_board == 7'd124)begin
					x_board <= 7'd35;
					y_board <= 7'd15;
				end
				else if(y_board == 7'd104)begin
					y_board <= 7'd15;
					x_board <= x_board + 1;
				end
				if(board_counter == 13'd8099)
					board_counter <= 13'b0;
			end
			
			else begin
				x_board <= 7'd35;
				y_board <= 7'd15;
				board_counter <= 13'b0;
			end
		end
	end
	
	
	//update cursor_pos and curr_board_colour
	reg [3:0]new_cursor_pos;
	reg [3:0]old_cursor_pos;
	always@(posedge clk)begin
		if(!resetn)begin
			new_cursor_pos <= 4'd4;
			old_cursor_pos <= 4'd4;
			curr_board_colour <= 9'b0;
		end
		else begin
			if(ld_new_cursor_pos)begin
				if(old_cursor_pos == 4'd0)begin
					if(right)
						new_cursor_pos <= 4'd1;
					else if(down)
						new_cursor_pos <= 4'd3;
				end
				else if(old_cursor_pos == 4'd1)begin
					if(left)
						new_cursor_pos <= 4'd0;
					else if(right)
						new_cursor_pos <= 4'd2;
					else if(down)
						new_cursor_pos <= 4'd4;
				end
				else if(old_cursor_pos == 4'd2)begin
					if(left)
						new_cursor_pos <= 4'd1;
					else if(down)
						new_cursor_pos <= 4'd5;
				end
				else if(old_cursor_pos == 4'd3)begin
					if(up)
						new_cursor_pos <= 4'd0;
					else if(right)
						new_cursor_pos <= 4'd4;
					else if(down)
						new_cursor_pos <= 4'd6;
				end
				else if(old_cursor_pos == 4'd4)begin
					if(up)
						new_cursor_pos <= 4'd1;
					else if(down)
						new_cursor_pos <= 4'd7;
					else if(left)
						new_cursor_pos <= 4'd3;
					else if(right)
						new_cursor_pos <= 4'd5;
				end
				else if(old_cursor_pos == 4'd5)begin
					if(up)
						new_cursor_pos <= 4'd2;
					else if(left)
						new_cursor_pos <= 4'd4;
					else if(down)
						new_cursor_pos <= 4'd8;
				end
				else if(old_cursor_pos == 4'd6)begin
					if(up)
						new_cursor_pos <= 4'd3;
					else if(right)
						new_cursor_pos <= 4'd7;
				end
				else if(old_cursor_pos == 4'd7)begin
					if(left)
						new_cursor_pos <= 4'd6;
					else if(right)
						new_cursor_pos <= 4'd8;
					else if(up)
						new_cursor_pos <= 4'd4;
				end
				else if(old_cursor_pos == 4'd8)begin
					if(up)
						new_cursor_pos <= 4'd5;
					else if(left)
						new_cursor_pos <= 4'd7;
				end
			end
			
			if(ld_old_cursor_pos)begin
				old_cursor_pos <= new_cursor_pos;
			end
			
			if(ld_board_colour)begin
				if(new_cursor_pos == 4'd0)
					curr_board_colour[0] <= !curr_board_colour[0];	
				else if(new_cursor_pos == 4'd1)
					curr_board_colour[1] <= !curr_board_colour[1];					
				else if(new_cursor_pos == 4'd2)
					curr_board_colour[2] <= !curr_board_colour[2];	
				else if(new_cursor_pos == 4'd3)
					curr_board_colour[3] <= !curr_board_colour[3];	
				else if(new_cursor_pos == 4'd4)
					curr_board_colour[4] <= !curr_board_colour[4];	
				else if(new_cursor_pos == 4'd5)
					curr_board_colour[5] <= !curr_board_colour[5];	
				else if(new_cursor_pos == 4'd6)
					curr_board_colour[6] <= !curr_board_colour[6];	
				else if(new_cursor_pos == 4'd7)	
					curr_board_colour[7] <= !curr_board_colour[7];	
				else if(new_cursor_pos == 4'd8)
					curr_board_colour[8] <= !curr_board_colour[8];	
			end
			
			if(change_adjacent)begin
				if(new_cursor_pos == 4'd0)begin
					curr_board_colour[1] <= !curr_board_colour[1];
					curr_board_colour[3] <= !curr_board_colour[3];						
				end
				else if(new_cursor_pos == 4'd1)begin
					curr_board_colour[0] <= !curr_board_colour[0];
					curr_board_colour[2] <= !curr_board_colour[2];
					curr_board_colour[4] <= !curr_board_colour[4];
				end	
				else if(new_cursor_pos == 4'd2)begin
					curr_board_colour[1] <= !curr_board_colour[1];
					curr_board_colour[5] <= !curr_board_colour[5];
				end	
				else if(new_cursor_pos == 4'd3)begin
					curr_board_colour[0] <= !curr_board_colour[0];
					curr_board_colour[4] <= !curr_board_colour[4];
					curr_board_colour[6] <= !curr_board_colour[6];
				end	
				else if(new_cursor_pos == 4'd4)begin
					curr_board_colour[1] <= !curr_board_colour[1];
					curr_board_colour[3] <= !curr_board_colour[3];
					curr_board_colour[5] <= !curr_board_colour[5];
					curr_board_colour[7] <= !curr_board_colour[7];
				end
				else if(new_cursor_pos == 4'd5)begin
					curr_board_colour[2] <= !curr_board_colour[2];
					curr_board_colour[4] <= !curr_board_colour[4];
					curr_board_colour[8] <= !curr_board_colour[8];
				end
				else if(new_cursor_pos == 4'd6)begin
					curr_board_colour[3] <= !curr_board_colour[3];
					curr_board_colour[7] <= !curr_board_colour[7];
				end
				else if(new_cursor_pos == 4'd7)begin
					curr_board_colour[4] <= !curr_board_colour[4];
					curr_board_colour[6] <= !curr_board_colour[6];
					curr_board_colour[8] <= !curr_board_colour[8];
				end
				else if(new_cursor_pos == 4'd8) begin
					curr_board_colour[5] <= !curr_board_colour[5];
					curr_board_colour[7] <= !curr_board_colour[7];
				end
			end
		end
	end
	
	
	//cursor_counter that sweep through a square
	reg [4:0]cursor_x_counter;
	reg [4:0]cursor_y_counter;
	always@(posedge clk)begin
		if(!resetn)begin
			cursor_counter <= 10'b0;
			cursor_x_counter <= 5'b0;
			cursor_y_counter <= 5'b0;
		end
		else begin
			if(draw_cursor || erase_cursor)begin
			
				cursor_counter <= cursor_counter + 1;
				cursor_y_counter <= cursor_y_counter + 1;
				if(cursor_x_counter == 5'd29 && cursor_y_counter == 5'd29)begin
					cursor_x_counter <= 5'b0;
					cursor_y_counter <= 5'b0;
				end
				else if(cursor_y_counter == 5'd29)begin
					cursor_y_counter <= 5'b0;
					cursor_x_counter <= cursor_x_counter + 1;
				end
				if(cursor_counter == 10'd899)
					cursor_counter <= 10'b0;
					
			end		
			else begin
				cursor_x_counter <= 5'b0;
				cursor_y_counter <= 5'b0;
				cursor_counter = 10'b0;
			end
		end
	end
	
	
	//x_pos and y_pos for plotting
	always@(*)begin
		if(initialize)begin
			x_out = x_initial;
			y_out = y_initial;
		end
		
		else if(draw_cursor)begin
			if(new_cursor_pos == 4'd0)begin
				x_out = 8'd35 + cursor_x_counter;
				y_out = 7'd15 + cursor_y_counter;
			end		
			else if(new_cursor_pos == 4'd1)begin
				x_out = 8'd65 + cursor_x_counter;
				y_out = 7'd15 + cursor_y_counter;
			end	
			else if(new_cursor_pos == 4'd2)begin
				x_out = 8'd95 + cursor_x_counter;
				y_out = 7'd15 + cursor_y_counter;
			end
			else if(new_cursor_pos == 4'd3)begin
				x_out = 8'd35 + cursor_x_counter;
				y_out = 7'd45 + cursor_y_counter;
			end
			else if(new_cursor_pos == 4'd4)begin
				x_out = 8'd65 + cursor_x_counter;
				y_out = 7'd45 + cursor_y_counter;
			end
			else if(new_cursor_pos == 4'd5)begin
				x_out = 8'd95 + cursor_x_counter;
				y_out = 7'd45 + cursor_y_counter;				
			end
			else if(new_cursor_pos == 4'd6)begin
				x_out = 8'd35 + cursor_x_counter;
				y_out = 7'd75 + cursor_y_counter;
			end
			else if(new_cursor_pos == 4'd7)begin
				x_out = 8'd65 + cursor_x_counter;
				y_out = 7'd75 + cursor_y_counter;	
			end		
			else if(new_cursor_pos == 4'd8) begin
				x_out = 8'd95 + cursor_x_counter;
				y_out = 7'd75 + cursor_y_counter;			
			end
			else begin
				x_out = 8'b0;
				y_out = 7'b0;
			end
		end
		else if(erase_cursor)begin
			if(old_cursor_pos == 4'd0)begin
				x_out = 8'd35 + cursor_x_counter;
				y_out = 7'd15 + cursor_y_counter;
			end
			else if(old_cursor_pos == 4'd1)begin
				x_out = 8'd65 + cursor_x_counter;
				y_out = 7'd15 + cursor_y_counter;			
			end
			else if(old_cursor_pos == 4'd2)begin
				x_out = 8'd95 + cursor_x_counter;
				y_out = 7'd15 + cursor_y_counter;
			end
			else if(old_cursor_pos == 4'd3)begin
				x_out = 8'd35 + cursor_x_counter;
				y_out = 7'd45 + cursor_y_counter;				
			end
			else if(old_cursor_pos == 4'd4)begin
				x_out = 8'd65 + cursor_x_counter;
				y_out = 7'd45 + cursor_y_counter;
			end
			else if(old_cursor_pos == 4'd5)begin
				x_out = 8'd95 + cursor_x_counter;
				y_out = 7'd45 + cursor_y_counter;	
			end
			else if(old_cursor_pos == 4'd6)begin
				x_out = 8'd35 + cursor_x_counter;
				y_out = 7'd75 + cursor_y_counter;	
			end
			else if(old_cursor_pos == 4'd7)begin
				x_out = 8'd65 + cursor_x_counter;
				y_out = 7'd75 + cursor_y_counter;
			end
			else if(old_cursor_pos == 4'd8)begin
				x_out = 8'd95 + cursor_x_counter;
				y_out = 7'd75 + cursor_y_counter;		
			end
			else begin
				x_out = 8'b0;
				y_out = 7'b0;			
			end
		end
		else if(update_board)begin
			x_out = x_board;
			y_out = y_board;
		end
		else if(end_display)begin
			x_out = x_initial;
			y_out = y_initial;
		end
		else if(start_display)begin
			x_out = x_initial;
			y_out = y_initial;
		end
		else if(instruction_display)begin
			x_out = x_initial;
			y_out = y_initial;
		end
		else begin
			x_out = 8'b0;
			y_out = 7'b0;
		end
	end
	
	//colour for plotting
	always@(*)begin
		if(initialize)begin
			//first square on the board
			if((x_initial > 8'd34 && x_initial < 8'd65) && (y_initial > 7'd14 && y_initial < 7'd45))begin
				if(curr_board_colour[0] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;
			end
			//second square
			else if((x_initial > 8'd64 && x_initial < 8'd95) && (y_initial > 7'd14 && y_initial < 7'd45))begin
				if(curr_board_colour[1] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;
			end
			//third square
			else if((x_initial > 8'd94 && x_initial < 8'd125) && (y_initial > 7'd14 && y_initial < 7'd45))begin
				if(curr_board_colour[2] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;		
			end
			//fourth square
			else if((x_initial > 8'd34 && x_initial < 8'd65) && (y_initial > 7'd44 && y_initial < 7'd75))begin
				if(curr_board_colour[3] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;				
			end
			//fifth square
			else if((x_initial > 8'd64 && x_initial < 8'd95) && (y_initial > 7'd44 && y_initial < 7'd75))begin
				if(curr_board_colour[4] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;				
			end
			//sixth square
			else if((x_initial > 8'd94 && x_initial < 8'd125) && (y_initial > 7'd44 && y_initial < 7'd75))begin
				if(curr_board_colour[5] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;				
			end
			//seventh square
			else if((x_initial > 8'd34 && x_initial < 8'd65) && (y_initial > 7'd74 && y_initial < 7'd105))begin
				if(curr_board_colour[6] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;					
			end
			//eighth square
			else if((x_initial > 8'd64 && x_initial < 8'd95) && (y_initial > 7'd74 && y_initial < 7'd105))begin
				if(curr_board_colour[7] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;					
			end
			//ninth square
			else if((x_initial > 8'd94 && x_initial < 8'd125) && (y_initial > 7'd74 && y_initial < 7'd105))begin
				if(curr_board_colour[8] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;					
			end	
			//board boundary as red
			else if((x_initial > 8'd29 && x_initial < 8'd130) && (y_initial > 7'd9 && y_initial < 7'd110))
					colour_out = 3'b100;
			//colour in black for the background
			else
				colour_out = 3'b000;
		end
		
		else if(draw_cursor)begin
			if((cursor_x_counter > 5'd2 && cursor_x_counter < 5'd27) && (cursor_y_counter > 5'd2 && cursor_y_counter < 5'd27))begin
				if(new_cursor_pos == 4'd0)begin
					if(curr_board_colour[0] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd1)begin
					if(curr_board_colour[1] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd2)begin
					if(curr_board_colour[2] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd3)begin
					if(curr_board_colour[3] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd4)begin
					if(curr_board_colour[4] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd5)begin
					if(curr_board_colour[5] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd6)begin
					if(curr_board_colour[6] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd7)begin
					if(curr_board_colour[7] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else if(new_cursor_pos == 4'd8) begin
					if(curr_board_colour[8] == 1'b0)
						colour_out = 3'b000;
					else
						colour_out = 3'b111;	
				end
				else
					colour_out = 3'b000;
			end	
			else begin
				colour_out = 3'b100;//colour the cursor in red
			end
		end
	
		else if(erase_cursor)begin
			if(old_cursor_pos == 4'd0)begin
				if(curr_board_colour[0] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd1)begin
				if(curr_board_colour[1] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd2)begin
				if(curr_board_colour[2] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd3)begin
				if(curr_board_colour[3] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd4)begin
				if(curr_board_colour[4] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd5)begin
				if(curr_board_colour[5] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd6)begin
				if(curr_board_colour[6] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd7)begin
				if(curr_board_colour[7] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else if(old_cursor_pos == 4'd8)begin
				if(curr_board_colour[8] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;	
			end
			else
				colour_out = 3'b000;	
		end
		
		else if(update_board)begin
			//first square on the board
			if((x_board > 8'd34 && x_board < 8'd65) && (y_board > 7'd14 && y_board < 7'd45))begin
				if(curr_board_colour[0] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;
			end
			//second square
			else if((x_board > 8'd64 && x_board < 8'd95) && (y_board > 7'd14 && y_board < 7'd45))begin
				if(curr_board_colour[1] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;
			end
			//third square
			else if((x_board > 8'd94 && x_board < 8'd125) && (y_board > 7'd14 && y_board < 7'd45))begin
				if(curr_board_colour[2] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;		
			end
			//fourth square
			else if((x_board > 8'd34 && x_board < 8'd65) && (y_board > 7'd44 && y_board < 7'd75))begin
				if(curr_board_colour[3] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;				
			end
			//fifth square
			else if((x_board > 8'd64 && x_board < 8'd95) && (y_board > 7'd44 && y_board < 7'd75))begin
				if(curr_board_colour[4] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;				
			end
			//sixth square
			else if((x_board > 8'd94 && x_board < 8'd125) && (y_board > 7'd44 && y_board < 7'd75))begin
				if(curr_board_colour[5] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;				
			end
			//seventh square
			else if((x_board > 8'd34 && x_board < 8'd65) && (y_board > 7'd74 && y_board < 7'd105))begin
				if(curr_board_colour[6] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;					
			end
			//eighth square
			else if((x_board > 8'd64 && x_board < 8'd95) && (y_board > 7'd74 && y_board < 7'd105))begin
				if(curr_board_colour[7] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;					
			end
			//ninth square
			else if((x_board > 8'd94 && x_board < 8'd125) && (y_board > 7'd74 && y_board < 7'd105))begin
				if(curr_board_colour[8] == 1'b0)
					colour_out = 3'b000;
				else
					colour_out = 3'b111;					
			end
			else
				colour_out = 3'b000;
		end
		
		else if(end_display)begin
			colour_out = end_colour;
		end
		else if(start_display)begin
			colour_out = start_colour;
		end
		else if(instruction_display)begin
			colour_out = instruction_colour;
		end
		else begin
			colour_out = 3'b000;
		end
	end

endmodule