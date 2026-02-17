module vga_demo(CLOCK_50, SW, KEY, LEDR, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
				PS2_CLK, PS2_DAT , HEX0, HEX1 , HEX4 , HEX5, AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK, AUD_XCK,AUD_DACDAT ,FPGA_I2C_SDAT, FPGA_I2C_SCLK);
	
    parameter RESOLUTION = "640x480"; 
    parameter COLOR_DEPTH = 9;

    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);

    parameter A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, 
              E = 4'b0100, F = 4'b0101, G = 4'b0110, INIT = 4'b0111,
              H = 4'b1000, I = 4'b1001, J = 4'b1010, K = 4'b1011;

	input wire CLOCK_50;	
	input wire [9:0] SW;
	input wire [3:0] KEY;
	output wire [9:0] LEDR;
	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_BLANK_N;
	output wire VGA_SYNC_N;
	output wire VGA_CLK;
	inout wire PS2_CLK; 
	inout wire PS2_DAT;
	output wire [6:0] HEX0, HEX1, HEX4, HEX5;

	wire [nX-1:0] O1_x, O2_x, O3_x, T1_x, T2_x;
	wire [nY-1:0] O1_y, O2_y, O3_y, T1_y, T2_y;
	wire [COLOR_DEPTH-1:0] O1_color, O2_color, O3_color, T1_color, T2_color;
    wire O1_write, O2_write, O3_write, T1_write, T2_write;
	reg [nX-1:0] MUX_x;
	reg [nY-1:0] MUX_y;
	reg [COLOR_DEPTH-1:0] MUX_color;
    reg MUX_write;
    wire req1, req2, req3, reqT1, reqT2;
    reg gnt1, gnt2, gnt3, gntT1, gntT2;
    reg [3:0] y_Q, Y_D;
    
    reg [3:0] init_delay;
	
    wire Resetn;
    wire [7:0] ps2_key_data;
    wire ps2_key_pressed;

    assign Resetn = KEY[0];
	
	      parameter STATE_INTRO = 2'b00;
	     parameter STATE_PLAYING = 2'b01;
	     parameter STATE_GAMEOVER = 2'b10;

	 
	 reg [1:0] game_state;
	
	 reg clear_screen;
	 reg [nX-1:0] clear_x;
	 reg [nY-1:0] clear_y;
	 wire clear_done;
	 reg trigger_clear;
	 
	
	 wire score_p1_add, score_p2_add;
	 reg [7:0] score_p1;
	 reg [7:0] score_p2;
	 wire [3:0] p1_tens = score_p1 / 10;
	 wire [3:0] p1_ones = score_p1 % 10;
	 wire [3:0] p2_tens = score_p2 / 10;
	 wire [3:0] p2_ones = score_p2 % 10;

	 

	 wire game_over;
	 wire player1_wins;
	 wire player2_wins;
	 reg game_over_latched;
	 reg player1_wins_latched; 

	 reg player2_wins_latched;  


	 reg [9:0] LEDR_ctrl;


	 wire [nX-1:0] start1_x, start2_x;
	 wire [nY-1:0] start1_y, start2_y;
	 wire start1_write, start2_write;
	 wire [COLOR_DEPTH-1:0] start1_color, start2_color;
	 wire reqS1, reqS2;
	 reg gntS1, gntS2;


	 wire [nX-1:0] go_screen_x;
	 wire [nY-1:0] go_screen_y;
	 wire go_screen_write;
	 wire [COLOR_DEPTH-1:0] go_screen_color;
	 wire reqGO;
	 reg gntGO;
	 
	 wire [nX-1:0] winner_text_x;
	 wire [nY-1:0] winner_text_y;
	 wire winner_text_write;
	 wire [COLOR_DEPTH-1:0] winner_text_color;
	 wire reqWIN1, reqWIN2, reqWIN;
	 reg gntWIN;
        PS2_Controller PS2(
        .CLOCK_50(CLOCK_50),
        .reset(~Resetn),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .received_data(ps2_key_data),
        .received_data_en(ps2_key_pressed)
    );

    // Keyboard control signals
    reg DIR1, DIR2;
    reg manual1_press, manual2_press;

    // Keyboard and state control
    always @(posedge CLOCK_50 or negedge Resetn) begin
        if (!Resetn) begin
            DIR1 <= 1'b0;
            DIR2 <= 1'b0;
            manual1_press <= 1'b0;
            manual2_press <= 1'b0;
            game_state <= STATE_INTRO;
            trigger_clear <= 1'b0;
            game_over_latched <= 1'b0;
            player1_wins_latched <= 1'b0;             player2_wins_latched <= 1'b0; 
        end 
        else begin
            trigger_clear <= 1'b0;
            
                        if (game_over && game_state == STATE_PLAYING) begin
                game_over_latched <= 1'b1;
                player1_wins_latched <= player1_wins;                player2_wins_latched <= player2_wins;                 game_state <= STATE_GAMEOVER;
                trigger_clear <= 1'b1;              end
            
            if (ps2_key_pressed && ps2_key_data == 8'h29) begin                  case (game_state)
                    STATE_INTRO: begin
                        game_state <= STATE_PLAYING;
                        trigger_clear <= 1'b1;
                    end
                    STATE_GAMEOVER: begin
                        game_state <= STATE_INTRO;
                        trigger_clear <= 1'b1;
                        game_over_latched <= 1'b0;
                        player1_wins_latched <= 1'b0;                         player2_wins_latched <= 1'b0;                      end
                    default: ;
                endcase
            end
                        if (ps2_key_pressed && game_state == STATE_PLAYING) begin
                case (ps2_key_data)
                    8'h1D: begin                         DIR1 <= 1'b1;
                        manual1_press <= 1'b1;
                    end
                    8'h1B: begin                        DIR1 <= 1'b0;
                        manual1_press <= 1'b1;
                    end
                    8'hE075: begin                        DIR2 <= 1'b1;
                        manual2_press <= 1'b1;
                    end
                    8'hE072: begin                         DIR2 <= 1'b0;
                        manual2_press <= 1'b1;
                    end
                    default: begin
                        manual1_press <= 1'b0;
                        manual2_press <= 1'b0;
                    end
                endcase
            end 
            else if (!ps2_key_pressed) begin
                manual1_press <= 1'b0;
                manual2_press <= 1'b0;
            end
        end
    end

    // Main state machine
    always @ (*)
        case (y_Q)
            INIT: if (init_delay == 4'd15) Y_D = A;
                  else Y_D = INIT;
            A:                  if (game_state == STATE_GAMEOVER && reqGO) Y_D = J;
                else if (game_state == STATE_GAMEOVER && reqWIN) Y_D = K;
                else if (game_state == STATE_INTRO && reqS1) Y_D = H;
                else if (game_state == STATE_INTRO && reqS2) Y_D = I;
                else if (game_state == STATE_PLAYING && req1) Y_D = B;
                else if (game_state == STATE_PLAYING && req2) Y_D = C;
                else if (game_state == STATE_PLAYING && req3) Y_D = E;
                else if (game_state == STATE_PLAYING && reqT1) Y_D = F;
                else if (game_state == STATE_PLAYING && reqT2) Y_D = G;
                else Y_D = A;
            B:  if (req1) Y_D = B;
                else if (reqT1) Y_D = F;
                else if (reqT2) Y_D = G;
                else Y_D = A;
            C:  if (req2) Y_D = C;
                else if (reqT1) Y_D = F;
                else if (reqT2) Y_D = G;
                else Y_D = A;
            E:  if (req3) Y_D = E;
                else if (reqT1) Y_D = F;
                else if (reqT2) Y_D = G;
                else Y_D = A;
            F:  if (reqT1) Y_D = F;
                else if (reqT2) Y_D = G;
                else Y_D = A;
            G:  if (reqT2) Y_D = G;
                else Y_D = A;
            H:  if (reqS1) Y_D = H;
                else if (reqS2) Y_D = I;
                else Y_D = A;
            I:  if (reqS2) Y_D = I;
                else Y_D = A;
            J:  if (reqGO) Y_D = J;
                else if (reqWIN) Y_D = K;
                else Y_D = A;
            K:  if (reqWIN) Y_D = K;
                else Y_D = A;
            default:  Y_D = INIT;
        endcase
        
    always @ (*)
    begin
        gnt1 = 1'b0; gnt2 = 1'b0; gnt3 = 1'b0; gntT1 = 1'b0; gntT2 = 1'b0; 
        gntS1 = 1'b0; gntS2 = 1'b0; gntGO = 1'b0; gntWIN = 1'b0; MUX_write = 1'b0;
        MUX_x = O1_x; MUX_y = O1_y; MUX_color = O1_color;
        case (y_Q)
            INIT: ;
            A:  ;
            B:  begin gnt1 = 1'b1; MUX_write = O1_write; 
                      MUX_x = O1_x; MUX_y = O1_y; MUX_color = O1_color; end
            C:  begin gnt2 = 1'b1; MUX_write = O2_write; 
                      MUX_x = O2_x; MUX_y = O2_y; MUX_color = O2_color; end
            E:  begin gnt3 = 1'b1; MUX_write = O3_write; 
                      MUX_x = O3_x; MUX_y = O3_y; MUX_color = O3_color; end
            F:  begin gntT1 = 1'b1; MUX_write = T1_write;
                      MUX_x = T1_x; MUX_y = T1_y; MUX_color = T1_color; end
            G:  begin gntT2 = 1'b1; MUX_write = T2_write;
                      MUX_x = T2_x; MUX_y = T2_y; MUX_color = T2_color; end
            H:  begin gntS1 = 1'b1; MUX_write = start1_write;
                      MUX_x = start1_x; MUX_y = start1_y; MUX_color = start1_color; end
            I:  begin gntS2 = 1'b1; MUX_write = start2_write;
                      MUX_x = start2_x; MUX_y = start2_y; MUX_color = start2_color; end
            J:  begin gntGO = 1'b1; MUX_write = go_screen_write;
                      MUX_x = go_screen_x; MUX_y = go_screen_y; MUX_color = go_screen_color; end
            K:  begin gntWIN = 1'b1; MUX_write = winner_text_write;
                      MUX_x = winner_text_x; MUX_y = winner_text_y; MUX_color = winner_text_color; end
        endcase
    end


    always @(posedge CLOCK_50)
        if (Resetn == 0) begin
            y_Q <= INIT;
            init_delay <= 4'd0;
        end
        else begin
            y_Q <= Y_D;
            if (y_Q == INIT && init_delay != 4'd15)
                init_delay <= init_delay + 1'b1;
        end

 
    wire paddle_resetn = Resetn && (game_state == STATE_PLAYING || game_state == STATE_INTRO);
	 // AUDIO 
	 input                AUD_ADCDAT;
inout                AUD_BCLK;
inout                AUD_ADCLRCK;
inout                AUD_DACLRCK;

inout                FPGA_I2C_SDAT;

output                AUD_XCK;
output                AUD_DACDAT;

output                FPGA_I2C_SCLK;

DE1_SoC_Audio_Example speaker(
    CLOCK_50,
    KEY,
    AUD_ADCDAT,
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK,
    play_sound,
    sound_type );
    
    object O1 (paddle_resetn, CLOCK_50, gnt1, DIR1, manual1_press, req1, O1_x, O1_y, O1_color, O1_write);
        defparam O1.RESOLUTION = RESOLUTION;
        defparam O1.nX = nX;
        defparam O1.nY = nY;
        defparam O1.COLOR_DEPTH = COLOR_DEPTH;
        defparam O1.X_INIT = 10'd5;
        defparam O1.Y_INIT = 9'd120;
        defparam O1.DEFAULT_COLOR = 9'b000000111;
        defparam O1.DRAW_IMMEDIATELY = 1;

    object O2 (paddle_resetn, CLOCK_50, gnt2, DIR2, manual2_press, req2, O2_x, O2_y, O2_color, O2_write);
        defparam O2.RESOLUTION = RESOLUTION;
        defparam O2.nX = nX;
        defparam O2.nY = nY;
        defparam O2.COLOR_DEPTH = COLOR_DEPTH;
        defparam O2.X_INIT = 10'd635;
        defparam O2.Y_INIT = 9'd120;
        defparam O2.DEFAULT_COLOR = 9'b111001111;
        defparam O2.DRAW_IMMEDIATELY = 1;

    wire ball_resetn = Resetn && game_state == STATE_PLAYING;
    
    static_ball O3 (
        .Resetn(ball_resetn),
        .Clock(CLOCK_50),
        .gnt(gnt3),
        .req(req3),
        .VGA_x(O3_x),
        .VGA_y(O3_y),
        .VGA_color(O3_color),
        .VGA_write(O3_write),
        .paddle1_x(O1_x),
        .paddle1_y(O1_y),
        .paddle2_x(O2_x),
        .paddle2_y(O2_y),
        .score_p1_add(score_p1_add),
        .score_p2_add(score_p2_add),
        .game_over(game_over),
        .player1_wins(player1_wins),
        .player2_wins(player2_wins)
    );
        defparam O3.RESOLUTION = RESOLUTION;
        defparam O3.nX = nX;
        defparam O3.nY = nY;
        defparam O3.COLOR_DEPTH = COLOR_DEPTH;

    // Player labels
    wire text_resetn = Resetn && game_state == STATE_PLAYING;
    
    text_object TEXT1 (text_resetn, CLOCK_50, gntT1, reqT1, T1_x, T1_y, T1_color, T1_write);
        defparam TEXT1.RESOLUTION = RESOLUTION;
        defparam TEXT1.nX = nX;
        defparam TEXT1.nY = nY;
        defparam TEXT1.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT1.TEXT_LENGTH = 8;
        defparam TEXT1.TEXT_STRING = "PLAYER 1";
        defparam TEXT1.SCALE = 2;
        defparam TEXT1.X_POS = 10'd50;
        defparam TEXT1.Y_POS = 9'd10;
        defparam TEXT1.TEXT_COLOR = 9'b000000111;

    text_object TEXT2 (text_resetn, CLOCK_50, gntT2, reqT2, T2_x, T2_y, T2_color, T2_write);
        defparam TEXT2.RESOLUTION = RESOLUTION;
        defparam TEXT2.nX = nX;
        defparam TEXT2.nY = nY;
        defparam TEXT2.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT2.TEXT_LENGTH = 8;
        defparam TEXT2.TEXT_STRING = "PLAYER 2";
        defparam TEXT2.SCALE = 2;
        defparam TEXT2.X_POS = 10'd492;
        defparam TEXT2.Y_POS = 9'd10;
        defparam TEXT2.TEXT_COLOR = 9'b111000111;

    // START SCREEN TEXT OBJECTS
    text_object TEXT_START1 (Resetn, CLOCK_50, gntS1, reqS1, start1_x, start1_y, start1_color, start1_write);
        defparam TEXT_START1.RESOLUTION = RESOLUTION;
        defparam TEXT_START1.nX = nX;
        defparam TEXT_START1.nY = nY;
        defparam TEXT_START1.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT_START1.TEXT_LENGTH = 10;
        defparam TEXT_START1.TEXT_STRING = "GAME START";
        defparam TEXT_START1.SCALE = 3;
        defparam TEXT_START1.X_POS = 10'd200;
        defparam TEXT_START1.Y_POS = 9'd180;
        defparam TEXT_START1.TEXT_COLOR = 9'b111111111;

    text_object TEXT_START2 (Resetn, CLOCK_50, gntS2, reqS2, start2_x, start2_y, start2_color, start2_write);
        defparam TEXT_START2.RESOLUTION = RESOLUTION;
        defparam TEXT_START2.nX = nX;
        defparam TEXT_START2.nY = nY;
        defparam TEXT_START2.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT_START2.TEXT_LENGTH = 16;
        defparam TEXT_START2.TEXT_STRING = "PRESS SPACE     ";
        defparam TEXT_START2.SCALE = 2;
        defparam TEXT_START2.X_POS = 10'd220;
        defparam TEXT_START2.Y_POS = 9'd280;
        defparam TEXT_START2.TEXT_COLOR = 9'b111111000;

    // GAME OVER TEXT OBJECTS
    text_object TEXT_GAMEOVER (Resetn, CLOCK_50, gntGO, reqGO, 
                               go_screen_x, go_screen_y, go_screen_color, go_screen_write);
        defparam TEXT_GAMEOVER.RESOLUTION = RESOLUTION;
        defparam TEXT_GAMEOVER.nX = nX;
        defparam TEXT_GAMEOVER.nY = nY;
        defparam TEXT_GAMEOVER.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT_GAMEOVER.TEXT_LENGTH = 9;
        defparam TEXT_GAMEOVER.TEXT_STRING = "GAME OVER";
        defparam TEXT_GAMEOVER.SCALE = 3;
        defparam TEXT_GAMEOVER.X_POS = 10'd240;
        defparam TEXT_GAMEOVER.Y_POS = 9'd150;
        defparam TEXT_GAMEOVER.TEXT_COLOR = 9'b111000000;

    wire [nX-1:0] winner1_text_x, winner2_text_x;
    wire [nY-1:0] winner1_text_y, winner2_text_y;
    wire [COLOR_DEPTH-1:0] winner1_text_color, winner2_text_color;
    wire winner1_text_write, winner2_text_write;

    text_object TEXT_WINNER1 (Resetn, CLOCK_50, gntWIN, reqWIN1, 
                              winner1_text_x, winner1_text_y, winner1_text_color, winner1_text_write);
        defparam TEXT_WINNER1.RESOLUTION = RESOLUTION;
        defparam TEXT_WINNER1.nX = nX;
        defparam TEXT_WINNER1.nY = nY;
        defparam TEXT_WINNER1.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT_WINNER1.TEXT_LENGTH = 14;
        defparam TEXT_WINNER1.TEXT_STRING = "PLAYER 1 WINS!";
        defparam TEXT_WINNER1.SCALE = 3;
        defparam TEXT_WINNER1.X_POS = 10'd180;
        defparam TEXT_WINNER1.Y_POS = 9'd250;
        defparam TEXT_WINNER1.TEXT_COLOR = 9'b000000111;

    text_object TEXT_WINNER2 (Resetn, CLOCK_50, gntWIN, reqWIN2, 
                              winner2_text_x, winner2_text_y, winner2_text_color, winner2_text_write);
        defparam TEXT_WINNER2.RESOLUTION = RESOLUTION;
        defparam TEXT_WINNER2.nX = nX;
        defparam TEXT_WINNER2.nY = nY;
        defparam TEXT_WINNER2.COLOR_DEPTH = COLOR_DEPTH;
        defparam TEXT_WINNER2.TEXT_LENGTH = 14;
        defparam TEXT_WINNER2.TEXT_STRING = "PLAYER 2 WINS!";
        defparam TEXT_WINNER2.SCALE = 3;
        defparam TEXT_WINNER2.X_POS = 10'd180;
        defparam TEXT_WINNER2.Y_POS = 9'd250;
        defparam TEXT_WINNER2.TEXT_COLOR = 9'b111000111;
    assign reqWIN = player1_wins_latched ? reqWIN1 : reqWIN2;
    assign winner_text_x = player1_wins_latched ? winner1_text_x : winner2_text_x;
    assign winner_text_y = player1_wins_latched ? winner1_text_y : winner2_text_y;
    assign winner_text_color = player1_wins_latched ? winner1_text_color : winner2_text_color;
    assign winner_text_write = player1_wins_latched ? winner1_text_write : winner2_text_write;

    // Screen clear logic
    assign clear_done = (clear_x == 639 && clear_y == 479);

    always @(posedge CLOCK_50 or negedge Resetn) begin
        if (!Resetn) begin
            clear_x <= 0;
            clear_y <= 0;
            clear_screen <= 1'b1;
        end
        else if (trigger_clear) begin
            clear_screen <= 1'b1;
            clear_x <= 0;
            clear_y <= 0;
        end
        else if (clear_screen && !clear_done) begin
            if (clear_x == 639) begin
                clear_x <= 0;
                clear_y <= clear_y + 1'b1;
            end
            else begin
                clear_x <= clear_x + 1'b1;
            end
        end
        else if (clear_done) begin
            clear_screen <= 1'b0;
            clear_x <= 0;
            clear_y <= 0;
        end
    end

    // Final MUX
    reg [nX-1:0] final_x;
    reg [nY-1:0] final_y;
    reg [COLOR_DEPTH-1:0] final_color;
    reg final_write;

    always @(*) begin
        if (clear_screen) begin
            final_x = clear_x;
            final_y = clear_y;
            final_color = {COLOR_DEPTH{1'b0}};
            final_write = 1'b1;
        end
        else begin
            final_x = MUX_x;
            final_y = MUX_y;
            final_color = MUX_color;
            final_write = MUX_write;
        end
    end

    // VGA Adapter
    vga_adapter VGA (
		.resetn(KEY[0]),
		.clock(CLOCK_50),
		.color(final_color),
		.x(final_x),
		.y(final_y),
		.write(final_write),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = RESOLUTION;
		defparam VGA.BACKGROUND_IMAGE = "./MIF/black_output.mif";
		defparam VGA.COLOR_DEPTH = COLOR_DEPTH;
reg [25:0] sound_timer;  
reg play_sound;
reg sound_type;  
always @(posedge CLOCK_50 or negedge Resetn) begin
    if (!Resetn) begin
        score_p1 <= 8'd0;
        score_p2 <= 8'd0;
        play_sound <= 0;
        sound_timer <= 0;
        sound_type <= 0;
    end 
    else if (game_state == STATE_INTRO) begin
        score_p1 <= 8'd0;
        score_p2 <= 8'd0;
        play_sound <= 0;
        sound_timer <= 0;
        sound_type <= 0;
    end 
    else if (game_state == STATE_PLAYING) begin
     
        if (score_p1_add) begin
            score_p1 <= score_p1 + 1'b1;
            play_sound <= 1;
            sound_type <= 0;              sound_timer <= 26'd2500000;         end

        if (score_p2_add) begin
            score_p2 <= score_p2 + 1'b1;
            play_sound <= 1;
            sound_type <= 0;            sound_timer <= 26'd2500000;          end

               if (sound_timer > 0) begin
            sound_timer <= sound_timer - 1'b1;
            play_sound <= 1;
        end
        else begin
            play_sound <= 0;
        end
    end
    else if (game_state == STATE_GAMEOVER) begin
               if (game_over_latched && sound_timer == 0) begin
            play_sound <= 1;
            sound_type <= 1;              sound_timer <= 26'd37500000;  
        end

               if (sound_timer > 0) begin
            sound_timer <= sound_timer - 1'b1;
            play_sound <= 1;
        end
        else begin
            play_sound <= 0;
        end
    end
end 


    // HEX displays
    hex_decoder HEX_P1_ONES (.bcd(p1_ones), .seg(HEX4));
    hex_decoder HEX_P1_TENS (.bcd(p1_tens), .seg(HEX5));
    hex_decoder HEX_P2_ONES (.bcd(p2_ones), .seg(HEX0));
    hex_decoder HEX_P2_TENS (.bcd(p2_tens), .seg(HEX1));

       assign LEDR = LEDR_ctrl;

    always @(*) begin
        if (game_state == STATE_GAMEOVER) begin
            if (player1_wins_latched) begin
                LEDR_ctrl = 10'b0000000001;
            end
            else if (player2_wins_latched) begin
                LEDR_ctrl = 10'b0000000010;
            end
            else begin
                LEDR_ctrl = 10'b0000000000;
            end
        end
        else begin
            LEDR_ctrl[9] = 1'b0;
            LEDR_ctrl[8:0] = SW[8:0];
        end
    end
					  
endmodule


module static_ball (
    Resetn, Clock, gnt, req, VGA_x, VGA_y, VGA_color, VGA_write,
    paddle1_x, paddle1_y, paddle2_x, paddle2_y,
    score_p1_add, score_p2_add,
    game_over, player1_wins, player2_wins
);
    
    parameter RESOLUTION = "160x120";
    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);
    parameter COLOR_DEPTH = 3;
    
    parameter XSCREEN = (RESOLUTION == "640x480") ? 640 : ((RESOLUTION == "320x240") ? 320 : 160);
    parameter YSCREEN = (RESOLUTION == "640x480") ? 480 : ((RESOLUTION == "320x240") ? 240 : 120);
    
    parameter BALL_RADIUS = (RESOLUTION == "640x480") ? 8 : ((RESOLUTION == "320x240") ? 4 : 2);
    parameter BALL_DIM = BALL_RADIUS * 2;
    
    parameter PADDLE_WIDTH = 4;
    parameter PADDLE_HEIGHT = YSCREEN>>3;
    
    parameter X_INIT = (RESOLUTION == "640x480") ? 10'd320 : 
                       ((RESOLUTION == "320x240") ? 9'd160 : 8'd80);
    parameter Y_INIT = (RESOLUTION == "640x480") ? 9'd240 : 
                       ((RESOLUTION == "320x240") ? 8'd120 : 7'd60);
    
    parameter ALT = {COLOR_DEPTH{1'b0}};
    parameter KK = 18;
    
    parameter A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011,
              E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111,
              I = 4'b1000, J = 4'b1001, K = 4'b1010, L = 4'b1011;
    
    input wire Resetn, Clock;
    input wire gnt;
    output reg req;
    output wire [nX-1:0] VGA_x;
    output wire [nY-1:0] VGA_y;
    output wire [COLOR_DEPTH-1:0] VGA_color;
    output wire VGA_write;
    output reg score_p1_add, score_p2_add;
    output reg game_over;
    output reg player1_wins;
    output reg player2_wins;
    
    reg prev_hit_p1, prev_hit_p2;
    
    input wire [nX-1:0] paddle1_x, paddle2_x;
    input wire [nY-1:0] paddle1_y, paddle2_y;
    
    wire [nX-1:0] X, XC, X0;
    wire [nY-1:0] Y, YC, Y0;
    wire [KK-1:0] slow;
    wire sync, Xdir, Ydir;
    reg Lx, Ly, Ex, Ey, Lxc, Lyc, Exc, Eyc;
    reg erase, Tdir_x, Tdir_y;
    reg [3:0] y_Q, Y_D;
    reg write;
    
    reg [3:0] init_count;
    
    assign X0 = X_INIT;
    assign Y0 = Y_INIT;
    
    UpDn_count U2 (X0, Clock, Resetn, Ex, Lx, Xdir, X);
        defparam U2.n = nX;
    UpDn_count U1 (Y0, Clock, Resetn, Ey, Ly, Ydir, Y);
        defparam U1.n = nY;
    
    UpDn_count U3 ({nX{1'd0}}, Clock, Resetn, Exc, Lxc, 1'b1, XC);
        defparam U3.n = nX;
    UpDn_count U4 ({nY{1'd0}}, Clock, Resetn, Eyc, Lyc, 1'b1, YC);
        defparam U4.n = nY;
    
    Up_count U6 (Clock, Resetn, slow);
        defparam U6.n = KK;
    
    assign sync = (slow == {KK{1'b1}});
    
    ToggleFF U7 (Tdir_x, Resetn, Clock, Xdir);
    ToggleFF U8 (Tdir_y, Resetn, Clock, Ydir);
    
    assign VGA_x = X + XC;
    assign VGA_y = Y + YC;
    
    wire [nX-1:0] dx, dy_extended;
    wire [nX+nX-1:0] dist_sq;
    wire in_circle;
    
    assign dx = (XC >= BALL_RADIUS) ? (XC - BALL_RADIUS) : (BALL_RADIUS - XC);
    assign dy_extended = (YC >= BALL_RADIUS) ? (YC - BALL_RADIUS) : (BALL_RADIUS - YC);
    assign dist_sq = (dx * dx) + (dy_extended * dy_extended);
    assign in_circle = (dist_sq <= (BALL_RADIUS * BALL_RADIUS));
    
    assign VGA_color = erase == 0 ? {COLOR_DEPTH{1'b1}} : ALT;
    assign VGA_write = write && in_circle;
    
    // Collision detection
    wire hit_paddle1_x, hit_paddle1_y, hit_paddle1;
    wire hit_paddle2_x, hit_paddle2_y, hit_paddle2;
    wire [nX-1:0] next_X;
    wire [nY-1:0] next_Y;
    
    assign next_X = Xdir ? (X + 1'b1) : (X - 1'b1);
    assign next_Y = Ydir ? (Y + 1'b1) : (Y - 1'b1);
    
    assign hit_paddle1_x = (next_X <= (paddle1_x + PADDLE_WIDTH)) && 
                           ((next_X + BALL_DIM) >= paddle1_x);
    assign hit_paddle1_y = (next_Y <= (paddle1_y + PADDLE_HEIGHT)) && 
                           ((next_Y + BALL_DIM) >= paddle1_y);
    assign hit_paddle1 = hit_paddle1_x && hit_paddle1_y;
    
    assign hit_paddle2_x = (next_X <= (paddle2_x + PADDLE_WIDTH)) && 
                           ((next_X + BALL_DIM) >= paddle2_x);
    assign hit_paddle2_y = (next_Y <= (paddle2_y + PADDLE_HEIGHT)) && 
                           ((next_Y + BALL_DIM) >= paddle2_y);
    assign hit_paddle2 = hit_paddle2_x && hit_paddle2_y;
    
    wire moving_left = !Xdir;
    wire moving_right = Xdir;
    
    wire should_bounce_paddle1 = hit_paddle1 && moving_left;
    wire should_bounce_paddle2 = hit_paddle2 && moving_right;
    
    wire hit_left_wall = (X == 0);
    wire hit_right_wall = (X == (XSCREEN - BALL_DIM));
    
    always @ (*)
        case (y_Q)
            A:  Y_D = D;
            B:  if (XC != BALL_DIM-1) Y_D = B;
                else Y_D = C;
            C:  if (YC != BALL_DIM-1) Y_D = B;
                else Y_D = D;
            D:  if (!sync) Y_D = D;
                else Y_D = E;
            E:  if (!gnt) Y_D = E;
                else Y_D = F;
            F:  if (XC != BALL_DIM-1) Y_D = F;
                else Y_D = G;
            G:  if (YC != BALL_DIM-1) Y_D = F;
                else Y_D = H;
            H:  Y_D = I;
            I:  Y_D = J;
            J:  if (XC != BALL_DIM-1) Y_D = J;
                else Y_D = K;
            K:  if (YC != BALL_DIM-1) Y_D = J;
                else Y_D = L;
            L:  if (game_over) Y_D = L;
                else Y_D = D;
            default: Y_D = A;
        endcase
    
    always @ (*)
    begin
        Lx = 1'b0; Ly = 1'b0; Lxc = 1'b0; Lyc = 1'b0; 
        Exc = 1'b0; Eyc = 1'b0; Ex = 1'b0; Ey = 1'b0;
        erase = 1'b0; write = 1'b0; Tdir_x = 1'b0; Tdir_y = 1'b0; req = 1'b0;
        case (y_Q)
            A:  begin Lx = 1'b1; Ly = 1'b1; Lxc = 1'b1; Lyc = 1'b1; end
            B:  begin Exc = 1'b1; write = 1'b1; end
            C:  begin Lxc = 1'b1; Eyc = 1'b1; end
            D:  Lyc = 1'b1;
            E:  req = 1'b1;
            F:  begin req = 1'b1; Exc = 1'b1; erase = 1'b1; write = 1'b1; end
            G:  begin req = 1'b1; Lxc = 1'b1; Eyc = 1'b1; end
            H:  begin 
                    req = 1'b1; 
                    Lyc = 1'b1; 
                    Tdir_y = (Y == 'd0) || (Y == YSCREEN-BALL_DIM);
                    Tdir_x = should_bounce_paddle1 || should_bounce_paddle2;
                end
            I:  begin req = 1'b1; Ex = 1'b1; Ey = 1'b1; end  
            J:  begin req = 1'b1; Exc = 1'b1; write = 1'b1; end
            K:  begin req = 1'b1; Lxc = 1'b1; Eyc = 1'b1; end
            L:  begin req = 1'b1; Lyc = 1'b1; Exc = 1'b1; write = 1'b1; end
        endcase
    end
    
    always @(posedge Clock)
        if (Resetn == 0)
            y_Q <= A;
        else
            y_Q <= Y_D;
    
    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            init_count <= 4'd0;
        end
        else if (init_count < 4'd15) begin
            init_count <= init_count + 1'b1;
        end
    end
    
    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            score_p1_add <= 1'b0;
            score_p2_add <= 1'b0;
            prev_hit_p1  <= 1'b0;
            prev_hit_p2  <= 1'b0;
        end else begin
            if (init_count >= 4'd15 && !game_over) begin
                score_p1_add <= should_bounce_paddle1 && !prev_hit_p1;
                score_p2_add <= should_bounce_paddle2 && !prev_hit_p2;
            end
            else begin
                score_p1_add <= 1'b0;
                score_p2_add <= 1'b0;
            end
            prev_hit_p1 <= should_bounce_paddle1;
            prev_hit_p2 <= should_bounce_paddle2;
        end
    end
    
   wall detection
    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            game_over <= 1'b0;
            player1_wins <= 1'b0;
            player2_wins <= 1'b0;
        end
        else if (init_count >= 4'd15 && !game_over && y_Q == H) begin
                      if (hit_left_wall) begin
                game_over <= 1'b1;
                player2_wins <= 1'b1;
                player1_wins <= 1'b0;
            end  else if (hit_right_wall) begin
                game_over <= 1'b1;
                player1_wins <= 1'b1;
                player2_wins <= 1'b0;
            end
                        else begin
                game_over <= game_over;
                player1_wins <= player1_wins;
                player2_wins <= player2_wins;
            end
        end
    end

endmodule



module sync(D, Resetn, Clock, Q);
    input wire D;
    input wire Resetn, Clock;
    output reg Q;
    reg Qi;

    always @(posedge Clock)
        if (Resetn == 0) begin
            Qi <= 1'b0;
            Q <= 1'b0;
        end
        else begin
            Qi <= D;
            Q <= Qi;
        end
endmodule

module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (Resetn == 0)
            Q <= 'b0;
        else if (E)
            Q <= R;
endmodule

module ToggleFF(T, Resetn, Clock, Q);
    input wire T, Resetn, Clock;
    output reg Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 1'b0;
        else if (T)
            Q <= ~Q;
endmodule

module UpDn_count (R, Clock, Resetn, E, L, UpDn, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Clock, Resetn, E, L, UpDn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (L == 1)
            Q <= R;
        else if (E)
            if (UpDn == 1)
                Q <= Q + 1'b1;
            else
                Q <= Q - 1'b1;
endmodule

module Up_count (Clock, Resetn, Q);
    parameter n = 8;
    input wire Clock, Resetn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 'b0;
        else 
            Q <= Q + 1'b1;
endmodule

module object (Resetn, Clock, gnt, direction_up, manual_press, req, VGA_x, VGA_y, VGA_color, VGA_write);

    parameter RESOLUTION = "160x120";
    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);
    parameter COLOR_DEPTH = 3;

    parameter XSCREEN = (RESOLUTION == "640x480") ? 640 : ((RESOLUTION == "320x240") ? 320 : 160);
    parameter YSCREEN = (RESOLUTION == "640x480") ? 480 : ((RESOLUTION == "320x240") ? 240 : 120);

    parameter XDIM = 4, YDIM = YSCREEN>>3;

    parameter X_INIT = (RESOLUTION == "640x480") ? 10'd439 : 
                            ((RESOLUTION == "320x240") ?  9'd219 : 8'd109);
    parameter Y_INIT = (RESOLUTION == "640x480") ? 9'd239 : 
                            ((RESOLUTION == "320x240") ?  8'd119 : 7'd59);
    parameter ALT = {COLOR_DEPTH{1'b0}};
    
    parameter DEFAULT_COLOR = {COLOR_DEPTH{1'b1}};
    parameter DRAW_IMMEDIATELY = 0;

    parameter A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011,
              E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111,
              I = 4'b1000, J = 4'b1001, K = 4'b1010, L = 4'b1011;

    input wire Resetn, Clock;
    input wire gnt;
    input wire direction_up;   
    input wire manual_press;   
    output reg req;
	output wire [nX-1:0] VGA_x;
	output wire [nY-1:0] VGA_y;
	output wire [COLOR_DEPTH-1:0] VGA_color;
    output wire VGA_write;

	wire [nX-1:0] X, XC, X0;
	wire [nY-1:0] Y, YC, Y0;
	wire [COLOR_DEPTH-1:0] color;
    reg Lx, Ly, Ey, Lxc, Lyc, Exc, Eyc; 
    wire Ydir;
    reg erase;
    reg [3:0] y_Q, Y_D;
    reg write;
    reg [4:0] move_count;  

    assign X0 = X_INIT;
    assign Y0 = Y_INIT;
    
    assign color = DEFAULT_COLOR;
    assign Ydir = direction_up;
    
    UpDn_count U2 (X0, Clock, Resetn, 1'b0, Lx, 1'b0, X);
        defparam U2.n = nX;

    reg [nY-1:0] Y_reg;
    assign Y = Y_reg;

    always @(posedge Clock) begin
        if (!Resetn)
            Y_reg <= Y0;
        else if (Ly)
            Y_reg <= Y0;
        else if (Ey) begin
            if (direction_up) begin
                if (Y_reg > 0)
                    Y_reg <= Y_reg - 1'b1;
            end
            else begin
                if (Y_reg < (YSCREEN - YDIM))
                    Y_reg <= Y_reg + 1'b1;
            end
        end
    end

    UpDn_count U3 ({nX{1'd0}}, Clock, Resetn, Exc, Lxc, 1'b1, XC);
        defparam U3.n = nX;

    UpDn_count U4 ({nY{1'd0}}, Clock, Resetn, Eyc, Lyc, 1'b1, YC);
        defparam U4.n = nY;

    reg manual_press_prev;
    wire manual_press_edge;
    
    always @(posedge Clock)
        if (Resetn == 0)
            manual_press_prev <= 1'b0;
        else
            manual_press_prev <= manual_press;
    
    assign manual_press_edge = manual_press && !manual_press_prev;

    assign VGA_x = X + XC;
    assign VGA_y = Y + YC;
    assign VGA_color = erase == 0 ? color : ALT;
    assign VGA_write = write;

    reg drawn_once;
    reg [3:0] reset_delay; 
    manual press
    always @(*) 
        case (y_Q)
            A:  Y_D = D;
            B:  if (XC != XDIM-1) Y_D = B;
                else Y_D = C;
            C:  if (YC != YDIM-1) Y_D = B;
                else Y_D = D;
            D:                 if ((DRAW_IMMEDIATELY && !drawn_once && reset_delay == 4'd15) || manual_press_edge)
                    Y_D = E;
                else
                    Y_D = D;
            E:  if (!gnt) Y_D = E;
                else Y_D = F;
            F:  if (XC != XDIM-1) Y_D = F;
                else Y_D = G;
            G:  if (YC != YDIM-1) Y_D = F;
                else Y_D = H;
            H:  Y_D = I;
            I:  if (move_count < 5'd20) Y_D = I;
                else Y_D = J;
            J:  if (XC != XDIM-1) Y_D = J;
                else Y_D = K;
            K:  if (YC != YDIM-1) Y_D = J;
                else Y_D = L;
            L:  Y_D = D;
            default: Y_D = A;
        endcase

    wire at_top, at_bottom;
    assign at_top    = (Y <= 0);
    assign at_bottom = (Y >= (YSCREEN - YDIM));

    always @(*) begin
        Lx = 1'b0; Ly = 1'b0; Lxc = 1'b0; Lyc = 1'b0;
        Exc = 1'b0; Eyc = 1'b0;
        erase = 1'b0; write = 1'b0; Ey = 1'b0; req = 1'b0;

        case (y_Q)
            A:  begin Lx = 1'b1; Ly = 1'b1; Lxc = 1'b1; Lyc = 1'b1; end
            B:  begin Exc = 1'b1; write = 1'b1; end
            C:  begin Lxc = 1'b1; Eyc = 1'b1; end
            D:  Lyc = 1'b1;
            E:  req = 1'b1;
            F:  begin req = 1'b1; Exc = 1'b1; erase = 1'b1; write = 1'b1; end
            G:  begin req = 1'b1; Lxc = 1'b1; Eyc = 1'b1; end
            H:  begin req = 1'b1; Lyc = 1'b1; end
            I:  begin 
                    req = 1'b1;
                    Ey = 1'b1;
                end
            J:  begin req = 1'b1; Exc = 1'b1; write = 1'b1; end
            K:  begin req = 1'b1; Lxc = 1'b1; Eyc = 1'b1; end
            L:  Lyc = 1'b1;
        endcase
    end

    always @(posedge Clock)
        if (Resetn == 0)
            move_count <= 5'd0;
        else if (y_Q == H)
            move_count <= 5'd0;  
        else if (y_Q == I && Ey)
            move_count <= move_count + 1'b1;

    always @(posedge Clock)
        if (Resetn == 0)
            y_Q <= A;
        else
            y_Q <= Y_D;
    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            drawn_once <= 1'b0;
            reset_delay <= 4'd0;
        end
        else begin
              if (reset_delay < 4'd15)
                reset_delay <= reset_delay + 1'b1;
            
                    if (y_Q == J || y_Q == K || y_Q == L)
                drawn_once <= 1'b1;
        end
    end

endmodule



module text_object (Resetn, Clock, gnt, req, VGA_x, VGA_y, VGA_color, VGA_write);
    
    parameter RESOLUTION = "160x120";
    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8);
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);
    parameter COLOR_DEPTH = 3;
    
    parameter TEXT_LENGTH = 8;
    parameter CHAR_WIDTH = 8;
    parameter CHAR_HEIGHT = 16;
    parameter SCALE = 2;
    
    parameter X_POS = 10'd10;
    parameter Y_POS = 9'd10;
    
    parameter [TEXT_LENGTH*8-1:0] TEXT_STRING = "DEFAULT ";
    parameter TEXT_COLOR = 9'b000000111;
    parameter ALT = {COLOR_DEPTH{1'b0}};
    
    parameter A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011, E = 3'b100;
    
    input wire Resetn, Clock;
    input wire gnt;
    output reg req;
    output reg [nX-1:0] VGA_x;
    output reg [nY-1:0] VGA_y;
    output reg [COLOR_DEPTH-1:0] VGA_color;
    output reg VGA_write;
    
    reg [2:0] y_Q, Y_D;
    reg [4:0] char_idx;
    reg [5:0] row_idx;
    reg [4:0] col_idx;
    
    wire [3:0] actual_row = row_idx / SCALE;
    wire [2:0] actual_col = col_idx / SCALE;
    
      function [7:0] get_char_row;
        input [7:0] ascii_char;
        input [3:0] row;
        begin
            case (ascii_char)
                "P": case(row)
                    4'd0:  get_char_row = 8'b11111100;
                    4'd1:  get_char_row = 8'b11111110;
                    4'd2:  get_char_row = 8'b11000110;
                    4'd3:  get_char_row = 8'b11000110;
                    4'd4:  get_char_row = 8'b11000110;
                    4'd5:  get_char_row = 8'b11111110;
                    4'd6:  get_char_row = 8'b11111100;
                    4'd7:  get_char_row = 8'b11000000;
                    4'd8:  get_char_row = 8'b11000000;
                    4'd9:  get_char_row = 8'b11000000;
                    4'd10: get_char_row = 8'b11000000;
                    default: get_char_row = 8'b00000000;
                endcase
                "L": case(row)
                    4'd0:  get_char_row = 8'b11000000;
                    4'd1:  get_char_row = 8'b11000000;
                    4'd2:  get_char_row = 8'b11000000;
                    4'd3:  get_char_row = 8'b11000000;
                    4'd4:  get_char_row = 8'b11000000;
                    4'd5:  get_char_row = 8'b11000000;
                    4'd6:  get_char_row = 8'b11000000;
                    4'd7:  get_char_row = 8'b11000000;
                    4'd8:  get_char_row = 8'b11000000;
                    4'd9:  get_char_row = 8'b11111110;
                    4'd10: get_char_row = 8'b11111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "A": case(row)
                    4'd0:  get_char_row = 8'b00111100;
                    4'd1:  get_char_row = 8'b01111110;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000011;
                    4'd4:  get_char_row = 8'b11000011;
                    4'd5:  get_char_row = 8'b11111111;
                    4'd6:  get_char_row = 8'b11111111;
                    4'd7:  get_char_row = 8'b11000011;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11000011;
                    4'd10: get_char_row = 8'b11000011;
                    default: get_char_row = 8'b00000000;
                endcase
                "Y": case(row)
                    4'd0:  get_char_row = 8'b11000011;
                    4'd1:  get_char_row = 8'b11000011;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b01100110;
                    4'd4:  get_char_row = 8'b01100110;
                    4'd5:  get_char_row = 8'b00111100;
                    4'd6:  get_char_row = 8'b00011000;
                    4'd7:  get_char_row = 8'b00011000;
                    4'd8:  get_char_row = 8'b00011000;
                    4'd9:  get_char_row = 8'b00011000;
                    4'd10: get_char_row = 8'b00011000;
                    default: get_char_row = 8'b00000000;
                endcase
                "E": case(row)
                    4'd0:  get_char_row = 8'b11111111;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b11000000;
                    4'd3:  get_char_row = 8'b11000000;
                    4'd4:  get_char_row = 8'b11111110;
                    4'd5:  get_char_row = 8'b11111110;
                    4'd6:  get_char_row = 8'b11000000;
                    4'd7:  get_char_row = 8'b11000000;
                    4'd8:  get_char_row = 8'b11000000;
                    4'd9:  get_char_row = 8'b11111111;
                    4'd10: get_char_row = 8'b11111111;
                    default: get_char_row = 8'b00000000;
                endcase
                "R": case(row)
                    4'd0:  get_char_row = 8'b11111100;
                    4'd1:  get_char_row = 8'b11111110;
                    4'd2:  get_char_row = 8'b11000110;
                    4'd3:  get_char_row = 8'b11000110;
                    4'd4:  get_char_row = 8'b11111110;
                    4'd5:  get_char_row = 8'b11111100;
                    4'd6:  get_char_row = 8'b11011000;
                    4'd7:  get_char_row = 8'b11001100;
                    4'd8:  get_char_row = 8'b11000110;
                    4'd9:  get_char_row = 8'b11000110;
                    4'd10: get_char_row = 8'b11000011;
                    default: get_char_row = 8'b00000000;
                endcase
                "C": case(row)
                    4'd0:  get_char_row = 8'b01111110;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000000;
                    4'd4:  get_char_row = 8'b11000000;
                    4'd5:  get_char_row = 8'b11000000;
                    4'd6:  get_char_row = 8'b11000000;
                    4'd7:  get_char_row = 8'b11000000;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11111111;
                    4'd10: get_char_row = 8'b01111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "1": case(row)
                    4'd0:  get_char_row = 8'b00011000;
                    4'd1:  get_char_row = 8'b00111000;
                    4'd2:  get_char_row = 8'b01111000;
                    4'd3:  get_char_row = 8'b00011000;
                    4'd4:  get_char_row = 8'b00011000;
                    4'd5:  get_char_row = 8'b00011000;
                    4'd6:  get_char_row = 8'b00011000;
                    4'd7:  get_char_row = 8'b00011000;
                    4'd8:  get_char_row = 8'b00011000;
                    4'd9:  get_char_row = 8'b01111110;
                    4'd10: get_char_row = 8'b01111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "2": case(row)
                    4'd0:  get_char_row = 8'b01111110;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b00000011;
                    4'd4:  get_char_row = 8'b00001110;
                    4'd5:  get_char_row = 8'b00111100;
                    4'd6:  get_char_row = 8'b01110000;
                    4'd7:  get_char_row = 8'b11000000;
                    4'd8:  get_char_row = 8'b11000000;
                    4'd9:  get_char_row = 8'b11111111;
                    4'd10: get_char_row = 8'b11111111;
                    default: get_char_row = 8'b00000000;
                endcase
                "G": case(row)
                    4'd0:  get_char_row = 8'b01111110;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000000;
                    4'd4:  get_char_row = 8'b11000000;
                    4'd5:  get_char_row = 8'b11001111;
                    4'd6:  get_char_row = 8'b11001111;
                    4'd7:  get_char_row = 8'b11000011;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11111111;
                    4'd10: get_char_row = 8'b01111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "M": case(row)
                    4'd0:  get_char_row = 8'b11000011;
                    4'd1:  get_char_row = 8'b11100111;
                    4'd2:  get_char_row = 8'b11111111;
                    4'd3:  get_char_row = 8'b11111111;
                    4'd4:  get_char_row = 8'b11011011;
                    4'd5:  get_char_row = 8'b11000011;
                    4'd6:  get_char_row = 8'b11000011;
                    4'd7:  get_char_row = 8'b11000011;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11000011;
                    4'd10: get_char_row = 8'b11000011;
                    default: get_char_row = 8'b00000000;
                endcase
                "S": case(row)
                    4'd0:  get_char_row = 8'b01111110;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000000;
                    4'd4:  get_char_row = 8'b11111110;
                    4'd5:  get_char_row = 8'b01111111;
                    4'd6:  get_char_row = 8'b00000011;
                    4'd7:  get_char_row = 8'b00000011;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11111111;
                    4'd10: get_char_row = 8'b01111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "T": case(row)
                    4'd0:  get_char_row = 8'b11111111;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b00011000;
                    4'd3:  get_char_row = 8'b00011000;
                    4'd4:  get_char_row = 8'b00011000;
                    4'd5:  get_char_row = 8'b00011000;
                    4'd6:  get_char_row = 8'b00011000;
                    4'd7:  get_char_row = 8'b00011000;
                    4'd8:  get_char_row = 8'b00011000;
                    4'd9:  get_char_row = 8'b00011000;
                    4'd10: get_char_row = 8'b00011000;
                    default: get_char_row = 8'b00000000;
                endcase
                "O": case(row)
                    4'd0:  get_char_row = 8'b01111110;
                    4'd1:  get_char_row = 8'b11111111;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000011;
                    4'd4:  get_char_row = 8'b11000011;
                    4'd5:  get_char_row = 8'b11000011;
                    4'd6:  get_char_row = 8'b11000011;
                    4'd7:  get_char_row = 8'b11000011;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11111111;
                    4'd10: get_char_row = 8'b01111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "V": case(row)
                    4'd0:  get_char_row = 8'b11000011;
                    4'd1:  get_char_row = 8'b11000011;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000011;
                    4'd4:  get_char_row = 8'b11000011;
                    4'd5:  get_char_row = 8'b11000011;
                    4'd6:  get_char_row = 8'b01100110;
                    4'd7:  get_char_row = 8'b01100110;
                    4'd8:  get_char_row = 8'b00111100;
                    4'd9:  get_char_row = 8'b00111100;
                    4'd10: get_char_row = 8'b00011000;
                    default: get_char_row = 8'b00000000;
						  
                endcase
					 "W": case(row)
                    4'd0:  get_char_row = 8'b11000011;
                    4'd1:  get_char_row = 8'b11000011;
                    4'd2:  get_char_row = 8'b11000011;
                    4'd3:  get_char_row = 8'b11000011;
                    4'd4:  get_char_row = 8'b11000011;
                    4'd5:  get_char_row = 8'b11011011;
                    4'd6:  get_char_row = 8'b11111111;
                    4'd7:  get_char_row = 8'b11111111;
                    4'd8:  get_char_row = 8'b11100111;
                    4'd9:  get_char_row = 8'b11000011;
                    4'd10: get_char_row = 8'b11000011;
                    default: get_char_row = 8'b00000000;
                endcase
                "I": case(row)
                    4'd0:  get_char_row = 8'b01111110;
                    4'd1:  get_char_row = 8'b01111110;
                    4'd2:  get_char_row = 8'b00011000;
                    4'd3:  get_char_row = 8'b00011000;
                    4'd4:  get_char_row = 8'b00011000;
                    4'd5:  get_char_row = 8'b00011000;
                    4'd6:  get_char_row = 8'b00011000;
                    4'd7:  get_char_row = 8'b00011000;
                    4'd8:  get_char_row = 8'b00011000;
                    4'd9:  get_char_row = 8'b01111110;
                    4'd10: get_char_row = 8'b01111110;
                    default: get_char_row = 8'b00000000;
                endcase
                "N": case(row)
                    4'd0:  get_char_row = 8'b11000011;
                    4'd1:  get_char_row = 8'b11100011;
                    4'd2:  get_char_row = 8'b11110011;
                    4'd3:  get_char_row = 8'b11111011;
                    4'd4:  get_char_row = 8'b11011011;
                    4'd5:  get_char_row = 8'b11001111;
                    4'd6:  get_char_row = 8'b11000111;
                    4'd7:  get_char_row = 8'b11000011;
                    4'd8:  get_char_row = 8'b11000011;
                    4'd9:  get_char_row = 8'b11000011;
                    4'd10: get_char_row = 8'b11000011;
                    default: get_char_row = 8'b00000000;
                endcase
                "!": case(row)
                    4'd0:  get_char_row = 8'b00011000;
                    4'd1:  get_char_row = 8'b00011000;
                    4'd2:  get_char_row = 8'b00011000;
                    4'd3:  get_char_row = 8'b00011000;
                    4'd4:  get_char_row = 8'b00011000;
                    4'd5:  get_char_row = 8'b00011000;
                    4'd6:  get_char_row = 8'b00011000;
                    4'd7:  get_char_row = 8'b00000000;
                    4'd8:  get_char_row = 8'b00000000;
                    4'd9:  get_char_row = 8'b00011000;
                    4'd10: get_char_row = 8'b00011000;
                    default: get_char_row = 8'b00000000;
                endcase
                " ": get_char_row = 8'b00000000;
                default: get_char_row = 8'b00000000;
            endcase
        end
    endfunction
    
       reg [7:0] current_char;
    integer bit_offset;
    always @(*) begin
        bit_offset = (TEXT_LENGTH - 1 - char_idx) * 8;
        if (char_idx < TEXT_LENGTH && bit_offset >= 0)
            current_char = TEXT_STRING[bit_offset +: 8];
        else
            current_char = " ";
    end
    
    wire [7:0] char_row_data = get_char_row(current_char, actual_row);
    wire char_pixel = char_row_data[7 - actual_col];

    always @ (*)
        case (y_Q)
            A: Y_D = B;
            B: Y_D = C;
            C: Y_D = D;
            D: if (col_idx == (CHAR_WIDTH * SCALE - 1)) Y_D = E;
               else Y_D = D;
            E: if (row_idx == (CHAR_HEIGHT * SCALE - 1) && char_idx == (TEXT_LENGTH - 1)) Y_D = A;
               else Y_D = B;
            default: Y_D = A;
        endcase
    
    always @ (*)
    begin
        req = 1'b0;
        VGA_write = 1'b0;
        VGA_color = ALT;
        VGA_x = X_POS + (char_idx * CHAR_WIDTH * SCALE) + col_idx;
        VGA_y = Y_POS + row_idx;
        
        case (y_Q)
            D: begin
                req = 1'b1;
                if (gnt && char_pixel) begin
                    VGA_write = 1'b1;
                    VGA_color = TEXT_COLOR;
                end
            end
        endcase
    end
    
    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            y_Q <= A;
            char_idx <= 0;
            row_idx <= 0;
            col_idx <= 0;
        end
        else begin
            y_Q <= Y_D;
            
            case (y_Q)
                D: if (gnt) col_idx <= col_idx + 1'b1;
                E: begin
                    col_idx <= 0;
                    if (row_idx == (CHAR_HEIGHT * SCALE - 1)) begin
                        row_idx <= 0;
                        if (char_idx == (TEXT_LENGTH - 1))
                            char_idx <= 0;
                        else
                            char_idx <= char_idx + 1'b1;
                    end
                    else begin
                        row_idx <= row_idx + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule

module hex_decoder (input [3:0] bcd, output reg [6:0] seg);
    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
