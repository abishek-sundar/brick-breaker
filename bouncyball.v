// Part 2 skeleton

module bouncyball
	(
		CLOCK_50,						//	On Board 50 MHz
		SW,
		KEY,
		HEX0,
		HEX1,
		HEX2,HEX3,HEX4,HEX5,
		// Your inputs and outputs here
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		PS2_DAT,
		PS2_CLK
	);

	input			CLOCK_50;				//	50 MHz
	input [9:0]SW;
	input [3:0]KEY;
	output [6:0]HEX0,HEX1,HEX2,HEX3, HEX4, HEX5;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	inout PS2_DAT;
	inout PS2_CLK;
	wire resetn;
	/*assign resetn = KEY[0];

	assign moveleft = ~KEY[3];
	assign moveright = ~KEY[2];*/
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire go;
	wire enter;
	assign resetn = ~enter;
	assign go = ~KEY[1];
	wire [5:0] colour;
	wire [9:0] x;
	wire [8:0] y;
	wire [3:0]tens;
	wire [3:0]hundreds;
	wire moveleft;
	wire moveright;
	wire writeEn;
	wire pause;
	wire speed;
	reg [14:0] memory;
	

	/*vga_controller vc1(	enable, resetn, colour, memory, 
	VGA_R, VGA_G, VGA_B,
	VGA_HS, VGA_VS, VGA_BLANK,
	VGA_SYNC, VGA_CLK);*/
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
		//	 Signals for the DAC to drive the monitor. 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	  ballpart p1(CLOCK_50, resetn, go,moveleft,moveright, x,y,colour,writeEn,tens,hundreds,pause,speed);
	  testkb kb1(CLOCK_50, PS2_DAT,PS2_CLK,~KEY[0],moveleft,moveright,pause,enter,speed);
	  
	  
	  hex_decoder one(4'b0,HEX0);
	  hex_decoder ten(tens,HEX1);
	  hex_decoder hundred(hundreds,HEX2);
	  hex_decoder null(4'b0, HEX3);
	  hex_decoder null1(4'b0, HEX4);
	  hex_decoder null2(4'b0, HEX5);
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
endmodule

module ballpart(
    input clk,
    input resetn,
    input go,
	 input moveleft,
	 input moveright,
	 
	 output [9:0]x_out,
	 output [8:0]y_out,
	 output [5:0]c_out,
	 output plot,
	 output [3:0]tens,
	 output [3:0]hundreds,
	 input pause,
	 input speed
    );
	 wire [9:0] score;
    // lots of wires to connect our datapath and control
    wire update,erasen,y_dir,hold,wait_for_go,iterate;
	 wire [1:0]x_dir;
    wire [9:0] count_xball;
	 wire [8:0] count_yball;
	 wire [9:0] count_xpaddle;
	 wire [5:0] counterx; 
	 wire [2:0] countery;  
	 wire [5:0] counter2;
	 wire [3:0] count_address;
	 wire plot_ball,plot_paddle,erasen_ball,erasen_paddle,rewrite;
	 wire colour,delete_brick, reset_ram1, reset_ram2;
	 wire hit;
	 wire draw_start, erasen_start, colour_start, colour_over, game_over;
	 wire load_pixel;
	 wire [17:0]brick_count;
	 wire [9:0]x_brick;
	 wire [8:0]y_brick;
	 wire [7:0] start_x;
	 wire [5:0] start_y;
	 wire [7:0] end_x;
	 wire [5:0] end_y;
	 wire colour_brick,plot_brick,update_brick,find_initial;
	 wire [4:0]delete_x,find_x;
	 wire [2:0]delete_y,find_y;
    wire found;
	 control C0(
		  .clk(clk),
		  .clk4(clk4),
		  .clk60(clk60),
		  .resetn(resetn),
		  .count_xball(count_xball),
		  .count_yball(count_yball),
		  .count_xpaddle(count_xpaddle),
		  .plot_ball(plot_ball),
		  .plot_paddle(plot_paddle),
		  .erasen_ball(erasen_ball),
		  .erasen_paddle(erasen_paddle),
		  .moveleft(moveleft),
		  .moveright(moveright),
		  .speed(speed),
		  .end_x(end_x),
		  .end_y(end_y),
		  .pause(pause),
		  .counterx(counterx),
		  .countery(countery),
		  .counter2(counter2),
		  .colour_over(colour_over),
		  .game_over(game_over),
		  .score(score),
		  .go(go),
		  .draw_start(draw_start), 
		  .erasen_start(erasen_start), 
		  .colour_start(colour_start),
		  .start_x(start_x),
		  .start_y(start_y),
		  .load_pixel(load_pixel),
		  .colour(colour),
		  .plot(plot),
		  .found(found),
		  .update(update),
		  .x_dir(x_dir),
		  .y_dir(y_dir),
		  .rewrite(rewrite),
		  .iterate(iterate),
		  .count_address(count_address),
		  .brick_count(brick_count),
		  .x_brick(x_brick),
		  .y_brick(y_brick),
		  .colour_brick(colour_brick),
		  .plot_brick(plot_brick),
		  .reset_ram1(reset_ram1),
		  .reset_ram2(reset_ram2),
		  .update_brick(update_brick),
		  .hold(hold),
		  .wait_for_go(Wait_for_go),
		  .hit(hit),
		  .delete_brick(delete_brick),
		  .delete_x(delete_x),
		  .delete_y(delete_y),
		  .find_x(find_x),
		  .find_y(find_y),
		  .find_initial(find_initial)
    );

    datapath D0(
			.x_in(count_xball),
			.y_in(count_yball),
			.x_in_paddle(count_xpaddle),
			.clk(clk),
			.resetn(resetn),
			.update(update),
			.plot_ball(plot_ball),
			.plot_paddle(plot_paddle),
			.erasen_ball(erasen_ball),
			.erasen_paddle(erasen_paddle),
	
			.x_dir(x_dir),
			.y_dir(y_dir),
			.colour(colour),
			.x_out(x_out),
			.y_out(y_out),
			.c_out(c_out),
			.counterx(counterx),
			.score(score),
			.countery(countery),
			.load_pixel(load_pixel),
		   .start_x(start_x),
		   .start_y(start_y),
			 .end_x(end_x),
		   .end_y(end_y),
			.counter2(counter2),
			.rewrite(rewrite),
			.moveleft(moveleft),
			.draw_start(draw_start), 
		   .erasen_start(erasen_start), 
		   .colour_start(colour_start),
			.moveright(moveright),
			.hit(hit),
			.brick_count(brick_count),
			.colour_brick(colour_brick),
			.tens(tens),
			.hundreds(hundreds),
			.plot_brick(plot_brick),
			.x_brick(x_brick),
			.y_brick(y_brick),
			.update_brick(update_brick),
		   .reset_ram1(reset_ram1),
		   .reset_ram2(reset_ram2),
			.colour_over(colour_over),
		   .game_over(game_over),
			.hold(hold),
			.wait_for_go(Wait_for_go),
			.found(found),
			.delete_brick(delete_brick),
			.delete_x(delete_x),
		   .delete_y(delete_y),
			.find_initial(find_initial),
			.find_x(find_x),
		   .find_y(find_y),
			.iterate(iterate),
		  .count_address(count_address)
    );
               
 endmodule        
           
			  
module control(
    input clk,
	 input clk4,
	 input clk60,
    input resetn,
    input go,
	 input moveright,
	 input moveleft,
	 input [1:0]x_dir,
	 input y_dir,
	 input found,hit,
	 input [9:0]score,
	 input pause,
	 input speed,       
	 //input black,
	 //input loadx,
    output reg plot, plot_ball,plot_paddle,hold, iterate, load_pixel, draw_start, erasen_start, colour_start,
    output reg  erasen_ball,erasen_paddle,update,colour, rewrite, reset_ram1,reset_ram2, colour_over, game_over,
	 output reg [9:0] count_xball,
	 output reg [8:0] count_yball,
	 output reg [9:0] count_xpaddle,
    output reg [3:0] count_address,
	 output reg [17:0]brick_count,
	 output reg [9:0] x_brick,
	 output reg [8:0] y_brick,
	 output reg colour_brick, plot_brick, update_brick,wait_for_go,delete_brick,find_initial,
	 output reg [7:0] start_x,
	 output reg [5:0] start_y,
	 output reg [7:0] end_x,
	 output reg [5:0] end_y,
	 output reg [5:0] counterx,
	 output reg [5:0] counter2,
	 output reg [2:0] countery,
	 
	 output reg[4:0]delete_x,find_x,
	 output reg[2:0]delete_y,find_y
	 
	
    );
	 reg [24:0] counter1;
	 
    reg [5:0] current_state, next_state; 
    
    localparam  WAIT 				= 5'd0,
					 DRAW_BALL			 = 5'd1,
					 WAIT_FOR_COUNT 	= 5'd2,
					 ERASE_BALL 		= 5'd3,
					 UPDATE_DIR			 = 5'd4,
					 WAIT_FOR_COUNT2 	= 5'd5,
					 COLOUR 				= 5'd6,
					 DRAW_PADDLE 		= 5'd7,
					 ERASE_PADDLE			= 5'd8,
					 MOVE = 				5'd9,
					 RESET_COUNTERS 	= 5'd10,
					 RESET_COUNTERS2	 = 5'd11,
					 COLOUR_BRICK	 	= 5'd12,
					 DRAW_BRICK 			= 5'd13,
					 UPDATE_BRICK 		= 5'd14,
					 WAIT_FOR_GO		 = 5'd15,
					 DELETE_BRICK		= 5'd16,
					 FIND_INITIAL_POS 		= 5'd17,
					 ITERATE_ADDRESSES 	= 5'd18,
					 WAIT_ONE_CLK 			= 5'd19,
					 ITERATE_COUNT_ADDRESS 	= 5'd20,
					 WAIT_1_CLK 			= 5'd21,
					 LOAD_PIXEL_COLOUR = 5'd22,
					 IF_FOUND = 5'd23,
					 REWRITE = 5'd24,
					 DRAW_START = 5'd25,
					 ERASE_START = 5'd26,
					 COLOUR_START = 5'd27,
					 GAME_OVER = 5'd28,
					 RESET_RAM1 = 5'd29,
					 RESET_RAM2 = 5'd30,
					 COLOUR_GAME_OVER = 5'd31,
					 WAIT_FOR_RESET = 6'd32,
					 PAUSE1 = 6'd33,
					 PAUSE2 = 6'd34,
					 PAUSE3 = 6'd35,
					 PAUSE4 = 6'd36
					 ;
					 //WAIT_FOR_ENABLE = 5'd5;
					 
				

    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
			case (current_state)
				WAIT: next_state = COLOUR_BRICK;
				COLOUR_BRICK: next_state = DRAW_BRICK;
				DRAW_BRICK: next_state = (x_brick == 10'd319 && y_brick == 9'd239) ? COLOUR_START :COLOUR_BRICK;
				
				
				COLOUR_START: next_state = DRAW_START;
			   DRAW_START: next_state = (start_x == 154 && start_y == 40) ? WAIT_FOR_GO : COLOUR_START;	
				WAIT_FOR_GO: next_state = (moveleft|moveright) ? ERASE_START: WAIT_FOR_GO;
				
				 //WAIT_FOR_ENABLE: next_state = enable60 ? DRAW : WAIT_FOR_ENABLE;
				 
				ERASE_START: next_state = (start_x == 154 && start_y == 40) ? ERASE_BALL : ERASE_START;
				ERASE_BALL: next_state = ((countery < 3'd7)) ? ERASE_BALL :  RESET_COUNTERS2 ;
				RESET_COUNTERS2: next_state = ((moveleft|moveright)? ERASE_PADDLE : UPDATE_DIR);
				ERASE_PADDLE: next_state = ((countery == 3'd3)&&(counterx == 6'd39)) ? MOVE:ERASE_PADDLE ;
				MOVE: next_state = UPDATE_DIR;
				UPDATE_DIR: next_state = ITERATE_ADDRESSES;
				
				
				ITERATE_ADDRESSES: next_state = (count_yball > 9'd239 | score == 340) ? COLOUR_GAME_OVER:WAIT_ONE_CLK;
				WAIT_ONE_CLK: next_state = (count_address > 7) ? DRAW_BALL:UPDATE_BRICK;
				UPDATE_BRICK: next_state = WAIT_1_CLK;	
				WAIT_1_CLK: next_state = hit? FIND_INITIAL_POS :ITERATE_COUNT_ADDRESS;
				
				
			//	WAIT_1_CLK: next_state = FIND_INITIAL_POS;
				FIND_INITIAL_POS: next_state = IF_FOUND;
				IF_FOUND: next_state = found ? DELETE_BRICK: LOAD_PIXEL_COLOUR;
				LOAD_PIXEL_COLOUR: next_state = WAIT_1_CLK;
				
				DELETE_BRICK: next_state =REWRITE; 
				REWRITE: next_state=(delete_x == 20 & delete_y == 7) ? ITERATE_COUNT_ADDRESS :DELETE_BRICK;
				ITERATE_COUNT_ADDRESS: next_state = ITERATE_ADDRESSES;
				
				DRAW_BALL: next_state =  ((countery < 3'd7)) ? COLOUR: RESET_COUNTERS;
				COLOUR: next_state = DRAW_BALL;
				RESET_COUNTERS: next_state = DRAW_PADDLE;
				DRAW_PADDLE: next_state = ((countery == 3'd3)&&(counterx == 6'd39)) ? WAIT_FOR_COUNT: DRAW_PADDLE;						
				WAIT_FOR_COUNT : next_state = counter1==25'd833334 ? PAUSE1 : WAIT_FOR_COUNT;
				PAUSE1: next_state = pause ? PAUSE2 : ERASE_BALL;
				PAUSE2: next_state = pause ? PAUSE2 : PAUSE3;
				PAUSE3: next_state = pause ? PAUSE4 : PAUSE3;
				PAUSE4: next_state = pause ? PAUSE4 : ERASE_BALL;
				COLOUR_GAME_OVER : next_state = GAME_OVER;
				GAME_OVER: next_state = (end_x == 154 && end_y == 40) ? WAIT_FOR_RESET : COLOUR_GAME_OVER;
				WAIT_FOR_RESET: next_state = (resetn) ? WAIT_FOR_RESET : RESET_RAM1;
				RESET_RAM1: next_state = RESET_RAM2;
				RESET_RAM2: next_state = (brick_count == 76800)? WAIT : RESET_RAM1;
			
				WAIT_FOR_COUNT2 : next_state = WAIT_FOR_COUNT;
				 
          
                 
            default:     next_state = WAIT;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  hold = 1'b0;
		  wait_for_go = 1'b0;
		  draw_start = 0;
		  plot = 1'b0;
		  erasen_start = 1;
		  update = 1'b0;
		  colour = 1'b0;
		  reset_ram1 = 0;
		  reset_ram2 = 0;
		  plot_ball = 1'b0;
		  plot_paddle=1'b0;
		  erasen_ball = 1'b1;
		  erasen_paddle = 1'b1;
		  colour_over = 0;
		  game_over = 0;
		  plot_brick = 1'b0;
		  colour_brick = 1'b0;
		  update_brick = 1'b0;
		  load_pixel = 0;		  
		  iterate = 0;
		  find_initial = 1'b0;
		  delete_brick = 1'b0;
		  rewrite = 0;
		  colour_start = 0;
        case (current_state)
		  
				WAIT: hold = 1'b1;
				
				WAIT_FOR_GO: wait_for_go = 1'b1;
				
				COLOUR: colour = 1'b1;
				COLOUR_START : colour_start = 1;
				REWRITE: rewrite = 1;
				ITERATE_ADDRESSES: iterate = 1;
				
				DELETE_BRICK: begin
					delete_brick = 1'b1;
					plot = 1'b1;
				end
				COLOUR_GAME_OVER: colour_over = 1;
				GAME_OVER: begin
					plot = 1;
					game_over = 1;
					end
				FIND_INITIAL_POS: find_initial = 1'b1;
				
				LOAD_PIXEL_COLOUR: load_pixel = 1;
				
				DRAW_BALL: begin
					plot = 1'b1;
					plot_ball = 1'b1;
				
				end
				DRAW_START: begin
				plot = 1;
				draw_start = 1;
				end
				ERASE_START: begin
				plot = 1;
				erasen_start = 0;
				end
            ERASE_BALL: begin
				plot = 1'b1;
				erasen_ball = 1'b0;
                end
            UPDATE_DIR: begin
                update = 1'b1;
                end
				DRAW_PADDLE : begin
				plot = 1'b1;
				plot_paddle = 1'b1;
				end
				
				COLOUR_BRICK: begin
				colour_brick = 1'b1;
				end
				
				DRAW_BRICK: begin
				plot =1'b1;
				plot_brick = 1'b1;
				end
			
				UPDATE_BRICK: begin
				update_brick = 1'b1;
				
				end
            ERASE_PADDLE: begin
					 plot = 1'b1;
                erasen_paddle = 1'b0;
                end
           RESET_RAM1: reset_ram1 = 1;
			  RESET_RAM2: reset_ram2 = 1;
				
        // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
	 always@(posedge clk) begin
	   if (!resetn | current_state==WAIT) begin
			counterx <= 0;
			countery <= 0;
			counter2 <= 0;
			count_address <= 0;
			x_brick <=0;
			y_brick<=0;
			brick_count<=0;
			delete_x<=0;
			delete_y<=0;
			find_x<=0;
			find_y<=0;
			start_x <= 0;
			start_y <= 0;
			end_x <= 0;
			end_y <= 0;
		end
		else if (current_state == GAME_OVER)begin
			end_x<=end_x+1;
			if (end_x == 154) begin
				end_y <= end_y + 1;
				end_x <= 0;
			end
		end
		else if(current_state == DELETE_BRICK)begin
			delete_x <= delete_x + 1;
			if (delete_x==20) begin
				delete_x <= 0;
				delete_y <= delete_y+1;
			end
		end
		
		else if(current_state == IF_FOUND)begin
			find_x <= find_x + 1;
			find_y<=find_y+1;
		end
		else if(current_state == DRAW_BRICK) begin
			brick_count <= brick_count+1;
			x_brick <= x_brick+1;
			if(x_brick == 10'd319)begin
			y_brick <= y_brick+1;
			x_brick <= 0;
			end
		end
		else if (current_state == ITERATE_COUNT_ADDRESS) begin
			find_x<=0;
			find_y<= 0;
			count_address = count_address + 1; end
		else if (current_state == ERASE_BALL ) begin 
			count_address <= 0;
			counterx <= counterx + 1;
			counter2 <= counter2 + 1;
			if (counterx == 3'd6) begin
				countery <= countery + 1;
				counterx <= 0;
				end
				
			end
		else if (current_state == RESET_COUNTERS) begin
			counterx <= 0;
			countery <= 0;
			counter2 <= 0;
			
			delete_x<=0;
			delete_y<=0;
			find_x<=0;
			find_y<=0;
			end
		else if (current_state == RESET_COUNTERS2) begin
			counterx <= 0;
			countery <= 0;
			counter2 <= 0;
		end
		else if (current_state == RESET_RAM2) begin
			brick_count <= brick_count+1;
			end
			
		
		else if (current_state == DRAW_PADDLE) begin
		
			counterx <= counterx + 1;
			if (counterx == 6'd39) begin
				countery <= countery + 1;
				counterx <= 0;
				end
			end
		else if (current_state == DRAW_START | current_state == ERASE_START)begin
			start_x<=start_x+1;
			if (start_x == 154) begin
				start_y <= start_y + 1;
				start_x <= 0;
			end
		
		end
		else if (current_state == WAIT_FOR_GO) begin
			start_x<=0;
			start_y<=0;
		end
		else if (current_state == ERASE_PADDLE) begin
			counterx <= counterx + 1;
			if (counterx == 6'd39) begin
				countery <= countery + 1;
				counterx <= 0;
				end
			end
		else if (current_state == WAIT_FOR_COUNT) begin
			counterx <= 0;
			countery <= 0;
			counter2 <= 0;
			end
		else if (current_state == WAIT_FOR_COUNT2) begin
			counterx <= 0;
			countery <= 0;
			counter2 <= 0;
			end
		else if (current_state == COLOUR) begin
			counter2 <= counter2 + 1;
			end
		else if (current_state == DRAW_BALL) begin 
				brick_count <= 0;
				x_brick <= 0;
				y_brick <= 0;
				
				counterx <= counterx + 1;
			if (counterx == 3'd6) begin
				countery <= countery + 1;
				counterx <= 0;
				end
			end
		else if (current_state == UPDATE_DIR) begin
				counterx <= 0;
				countery <= 0;
				counter2 <= 0;
			end
	end
	

always@(posedge clk) begin
if (!resetn | current_state==WAIT) begin	

		counter1<=0;
		count_xball<=157;
		count_yball<=229;
		count_xpaddle<=140;
		
		end
else if (current_state == WAIT_FOR_COUNT) begin
	counter1<=counter1+1;
	end
else if (current_state == WAIT_FOR_COUNT2) begin
	counter1<=counter1+1;
	end
	else if (current_state == DRAW_BALL) begin
	
	counter1<=0;
	end
else if (current_state == ERASE_BALL) begin
	counter1<=0;
	end	
else if (current_state == UPDATE_DIR)begin 
	if (speed == 0) begin
	if (x_dir == 1) count_xball = count_xball - 1;
	if (x_dir == 0) count_xball = count_xball - 2;
	if (x_dir == 2) count_xball = count_xball + 1;
	if (x_dir == 3) count_xball = count_xball + 2;
	if (y_dir == 1) count_yball = count_yball + 1;
	if (y_dir == 0) count_yball = count_yball - 1;
	end else if (speed == 1) begin
	if (x_dir == 1) count_xball = count_xball - 2;
	if (x_dir == 0) count_xball = count_xball - 4;
	if (x_dir == 2) count_xball = count_xball + 2;
	if (x_dir == 3) count_xball = count_xball + 4;
	if (y_dir == 1) count_yball = count_yball + 2;
	if (y_dir == 0) count_yball = count_yball - 2;
	end
	end
else if (current_state == MOVE)begin 
	if (moveleft & (count_xpaddle==0) ) count_xpaddle <= 0;
	else if (moveright & (count_xpaddle==10'd280) ) count_xpaddle <= 10'd280;
	else if (moveleft) begin
		count_xpaddle <= count_xpaddle - 5'd5;
	end
	else if (moveright) begin
		count_xpaddle <= count_xpaddle + 5'd5;
	end

	end
end


    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= RESET_RAM1;
			
        else
            current_state <= next_state;
    end // state_FFS
endmodule
/*module blackScreen(clk,black,x_out,y_out);
	output reg x_out;
	output reg y_out;
	input clk;
	input black;
	reg [13:0]count;
	always @ (posedge clk) begin
		if (black) begin
			x_out <= count[6:0];
			y_out <= count[13:7];
		
			count <= count + 1;
		end
		else begin
		count <= 0;
		
		x_out <= 0;
		y_out <= 0;
		end
end
endmodule*/
module datapath(
    input clk,
    input resetn,
	 
	 input update,hold,wait_for_go,

	 input colour,
	 input [9:0]x_in,
	 input [9:0]x_in_paddle,
	 input [8:0]y_in,
	 input [5:0]counterx,
	 input [2:0]countery,
	 input [5:0]counter2,
	 input plot_ball, iterate,
	 input plot_paddle,
	 input erasen_ball,
	 input erasen_paddle,
	 input [3:0]count_address,
	 input colour_brick,plot_brick,update_brick, reset_ram1,reset_ram2,colour_over, game_over,
	 input [9:0]x_brick,
	 input [8:0]y_brick,
	 input [17:0]brick_count,
	 input moveleft,moveright,rewrite,
	 input [7:0] start_x,
	 input [5:0] start_y,
	 input [7:0] end_x,
	 input [5:0] end_y,
	 input draw_start, erasen_start, colour_start,
	 input delete_brick,find_initial,load_pixel,
	 input [4:0]delete_x,find_x,
	 input [2:0]delete_y,find_y,
	 
	 output reg [3:0]tens,
	 output reg [3:0]hundreds,
	 output reg [9:0]score,
	 output reg [9:0]x_out,
	 output reg [8:0]y_out,
	 output reg [1:0]x_dir,
	 output reg y_dir,
	 output reg [5:0]c_out,
	 output reg found,hit
    );

    // input registers
	 wire [5:0]c_wire;
	 wire [5:0]c_start;
	 wire [5:0]colour_out;
	 reg [5:0]rewrite_colour;
	 wire [5:0]zero = counter2;
	wire [5:0]c_brick;//c_top,c_left,c_right,c_bottom;
	 wire [5:0] c_dir;
	 wire [5:0] c_win;
	 wire [5:0] c_lose;
	 wire [5:0]find_bottom;
	 reg [9:0]x_find;
	 reg [8:0]y_find;
	 reg rewrite_ram;
	 reg x_done = 0;
	 reg [12:0]address_start;
	 reg [12:0]address_end;
	 reg [16:0]address;
	 Ball7 nb(counter2, clk, zero, 0, c_wire);
	 start_game_screen sgs(address_start, clk, zero, 0, c_start);
	 you_win W(address_end, clk, zero, 0, c_win);
	 you_lose L(address_end,clk,zero,0,c_lose);
	 bricks_full test(brick_count,clk,zero,0,c_brick);
	 bricks_full write_test_bottom(address,clk,rewrite_colour,rewrite_ram,c_dir);
    always@(posedge clk) begin
        if(!resetn) begin
            x_out <= 10'b0; 
            y_out <= 9'b0; 
				address <= 0;
            c_out <= 3'b0; 
				x_dir <= 2;
				y_dir <= 1;
				found <= 0;
				rewrite_ram <= 0;
				rewrite_colour = 6'b0;
				address_end <= 0;
        end
        else begin
		  
				if(hold) begin
					x_out <= 10'b0; 
					y_out <= 9'b0; 
					address <= 0;
					c_out <= 3'b0; 
					x_dir <= 2;
					y_dir <= 1;
					score <= 0;
					tens<=0;
					hundreds<=0;
					address_end <= 0;
				end
				if (colour_over) begin
					address_end <= (end_x + 155*end_y);
				end
				
				if (game_over)begin
					if (score == 340)c_out <= c_win;
					else c_out <= c_lose;
					x_out <= 82 + end_x;
					y_out <= 136 + end_y;
						
				end
				if(wait_for_go)begin
					y_dir <= 0;
					if(moveleft) x_dir <= 1;
					if(moveright) x_dir <=2;
				
				end
				if(colour_brick) c_out <= c_brick;
				
				if(plot_brick) begin
					x_out <= x_brick;
					y_out <= y_brick;
		  
				end
				if (load_pixel) address <= (x_find + (320*y_find));
			
				if (iterate) begin
				rewrite_ram <= 0;
				found <= 0;
				hit <= 0;
				x_done <= 0;
					case (count_address) 
						0: address <= x_in+3+((y_in-1)*320); //top of ball
						1: address <= x_in+3+((y_in+8)*320); //bottom of ball
					   2: address <= x_in+8+((y_in+3)*320);// right of ball
						3: address <= x_in-1+((y_in+3)*320); //left of ball
						4: address <= x_in + (y_in*320); // top left of ball
						5: address <= x_in + ((y_in+6)*320); //bottom left of ball
						6: address <= x_in + 6 + (y_in*320); //top right of ball
						7: address <= x_in + 6 + ((y_in+6)*320); //bottom right of ball 
					endcase
				end
				if(find_initial)begin
					case (count_address)
					
					   0: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in-1;
									x_find <= x_in + 3 - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
						1: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in+8;
									x_find <= x_in+3  - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
							
						2: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in+3;
									x_find <= x_in+8  - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
							
						3: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in+3;
									x_find <= x_in-1  - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
							
						4: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in;
									x_find <= x_in  - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
						5: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in+6;
									x_find <= x_in  - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
							6: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in;
									x_find <= x_in + 6  - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
							7: begin
							if (c_dir == 6'b110000 & !x_done) begin
									y_find <= y_in+6;
									x_find <= x_in + 6 - find_x; end
							else if (c_dir == 6'b0 & !x_done) begin
									x_find <= x_find + 1;
									x_done <= 1; end
							else if (c_dir == 6'b110000 & x_done) 
									y_find <= y_find - 1;
							else if (c_dir == 6'b0 & x_done) begin
									y_find <= y_find + 1;
									found <= 1; end
								end
					endcase
				end
				if (delete_brick) begin
					c_out <= 6'b0;
					rewrite_colour = 6'b0;
					x_out <= x_find + delete_x;
					y_out <= y_find + delete_y;
				end
				if (rewrite) begin
				address <= (x_out + (y_out*320));
				rewrite_ram <= 1;
				end
				if(update_brick)begin
					if (c_dir == 6'b110000) begin
						hit <= 1;
						score <= score + 10;
						tens<=tens+1;
						if (tens == 9) begin
							hundreds <= hundreds + 1;
							tens <= 0;
							end
					
						case (count_address) 
							0: y_dir<=1;
							1: y_dir<=0;
							2: begin
								if (x_dir == 2) x_dir<=1;
								else if (x_dir == 3) x_dir <= 0;
							end
							3: begin
								if (x_dir == 0) x_dir<=3;
								else if (x_dir == 1) x_dir <= 2;
							end
							4: begin 
								y_dir<=1;
								if (x_dir == 0) x_dir<=3;
								else if (x_dir == 1) x_dir <= 2;		
								end
							5: begin
								y_dir<=0;				
								if (x_dir == 0) x_dir<=3;
								else if (x_dir == 1) x_dir <= 2;			
								end
							6: begin
								y_dir<=1;		
								if (x_dir == 2) x_dir<=1;
								else if (x_dir == 3) x_dir <= 0;	
								end
							7: begin
								y_dir<=0;		
								if (x_dir == 2) x_dir<=1;
								else if (x_dir == 3) x_dir <= 0;
								end
								
						endcase		
					end
				end
				if (colour) c_out <= c_wire;
				
				if(plot_ball) begin
			
			
					x_out <= x_in + counterx[2:0];
					y_out <= y_in + countery[2:0];
					end
						 
            if(!erasen_ball) begin
					c_out <= 6'b000000;
					x_out <= x_in + counterx[2:0];
					y_out <= y_in + countery[2:0];
					end
                 
          if(update) begin
                if (x_in == 10'd312 | x_in == 10'd313 | x_in == 314 | x_in == 315 | x_in == 316) begin
					 if (x_dir == 2) x_dir <= 1;
					 if (x_dir == 3) x_dir <= 0;
					 end
					 if (x_in == 2 | x_in == 1 | x_in == 0 | x_in < 0)begin
					 if (x_dir == 0) x_dir <= 3;
					 if (x_dir == 1) x_dir <= 2;
					 end
					 
					 if (y_in == 2 | y_in == 3| y_in == 1 | y_in == 0 | y_in == 255 | y_in == 254 | y_in == 253) y_dir <= 1;
					 if (x_in_paddle < 7) begin
					 if (y_in > 9'd229 & y_in <= 9'd232 & x_in >= 0& x_in < x_in_paddle + 41) begin
						 y_dir <= 0;
						 if (x_in>=x_in_paddle & x_in<x_in_paddle + 10) x_dir <= 2'd0;
						 if (x_in>=x_in_paddle+10 & x_in<x_in_paddle + 20) x_dir <= 2'd1;
						 if (x_in>=x_in_paddle+20 & x_in<x_in_paddle + 30) x_dir <= 2'd2;
						 if (x_in>=x_in_paddle+30 & x_in<x_in_paddle + 41) x_dir <= 2'd3;
					 end
					 end
					 else if (x_in_paddle>=7)begin
					 if (y_in > 9'd229 & y_in <= 9'd232 & x_in >= x_in_paddle-7& x_in < x_in_paddle + 41) begin
						 y_dir <= 0;
						 if (x_in>=x_in_paddle-7 & x_in<x_in_paddle + 5) x_dir <= 2'd0;
						 if (x_in>=x_in_paddle+5 & x_in<x_in_paddle + 17) x_dir <= 2'd1;
						 if (x_in>=x_in_paddle+17 & x_in<x_in_paddle + 29) x_dir <= 2'd2;
						 if (x_in>=x_in_paddle+29 & x_in<x_in_paddle + 41) x_dir <= 2'd3;
					 end
					 end
					 end
				if(plot_paddle) begin
			c_out <= 6'b111111;
			
			x_out <= x_in_paddle + counterx[5:0];
			y_out <=  9'd236 + countery[2:0];
		end
			 
	if(!erasen_paddle) begin
			c_out <= 3'b000;
			x_out <= x_in_paddle + counterx[5:0];
			y_out <= 9'd236 + countery[2:0];
		end
		if (!erasen_start)begin
			c_out <= 3'b0;
			x_out <= 82 + start_x;
			y_out <= 136 + start_y;
		end
		if (draw_start) begin
			c_out <= c_start;
			x_out <= 82 + start_x;
			y_out <= 136 + start_y;
		end
		if (colour_start) begin
			address_start <= (start_x + 155*start_y);
		end 
		if (reset_ram1) begin
			score <= 0;
			tens <= 0;
			hundreds <= 0;
			address <= brick_count;
		end
		if (reset_ram2) begin
			rewrite_colour = c_brick;
			rewrite_ram <= 1;
		end
	end
end
	
    
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_0000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule