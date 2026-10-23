module Audio_codec(input clk,rst,
						 input  wire ac_recdat,
						 input  wire playback_en,
						 output wire ac_mclk,
						 output wire ac_bclk,
						 output wire ac_pblrc,
						 output wire ac_reclrc,
						 output reg ac_pbdat,
						 output reg ac_scl,
						 inout  wire ac_sda,
						 output reg sample_ready,
						 input  wire [15:0] audio_in_16b,
						 output reg  [15:0] audio_out_16b,
						 output wire i2c_done);
						 
assign ac_mclk = clk_div[1];

reg sda_out;
assign ac_sda = (sda_out == 1'b0) ? 1'b0 : 1'bz;

assign i2c_done = (state == DONE);        // 1 when I2C initialization finishes

reg bclk_reg;
reg lrck_reg;
reg [3:0] clk_div;
reg [5:0]  bit_count;
reg [15:0] rx_left_shift;
reg [15:0] rx_right_shift;
reg [15:0] tx_shift;
reg [15:0] left_sample_buf;
reg [15:0] right_sample_buf;
reg [3:0]  rom_idx;
reg [15:0] rom_word;
reg [6:0]  i2c_div;
reg [23:0] shift_buf;
reg [15:0] i2c_bit_count;
reg [15:0] gap_timer;
reg [3:0]  state;				 
						 
assign ac_bclk   = bclk_reg;
assign ac_pblrc  = lrck_reg;
assign ac_reclrc = lrck_reg;
						 
parameter TOTAL_REGS = 15;

parameter
			IDLE 		  	  = 4'b0000,
			START 		  = 4'b0001,
			BIT_LOW 	  	  = 4'b0010,
			BIT_HIGH 	  = 4'b0011,
			STOP_LOW	  	  = 4'b0100,
			STOP_HIGH_SCL = 4'b0101,
			STOP_HIGH_SDA = 4'b0110,
			GAP 		  	  = 4'b0111,
			DONE 		  	  = 4'b1000;
			
always @(posedge clk)
begin
		if(~rst)
		begin
				clk_div 			  <= 0;
				bit_count 		  <= 0;
				rx_left_shift 	  <= 0;
				rx_right_shift   <= 0;
				tx_shift 		  <= 0;
				left_sample_buf  <= 0;
				right_sample_buf <= 0;
				rom_idx			  <= 0;
				i2c_div			  <= 0;
				shift_buf		  <= 0;
				i2c_bit_count	  <= 0;
				gap_timer		  <= 0;
				ac_pbdat			  <= 0;
				sample_ready	  <= 0;
				audio_out_16b	  <= 0;
				bclk_reg			  <= 0;
				lrck_reg 		  <= 0;
				ac_scl			  <= 1;
				sda_out			  <= 1;	
				state				  <= IDLE;			
				rom_word			  <= {7'h0F,9'b0_0000_0000};
		end
		
		else
		begin
				clk_div <= clk_div + 1;
				
				sample_ready <= (clk_div == 4'd4 && bit_count == 6'd17);

				
				if(clk_div == 4'd0)
				begin
						bclk_reg <= 1;
				end
				
				else if(clk_div == 4'd8)
				begin
						bclk_reg <= 0;		
				end
				
				if(clk_div == 4'd8)
				begin
						if (!i2c_done)
						begin
							   ac_pbdat <= 0; // Mute DAC during power-on for the first time
						end
						
						else if((bit_count >= 6'd0 && bit_count <= 6'd15)||(bit_count >= 6'd32 && bit_count <= 6'd48))
						begin
								ac_pbdat <= tx_shift[15];
								tx_shift <= {tx_shift[14:0],1'b0};
						end
								
						else
						begin
								ac_pbdat <= 0;
						end
				end				
				
				if(clk_div == 4'd4)
				begin
						if(bit_count >= 6'd0 && bit_count <= 6'd16)
						begin
								rx_left_shift <= {rx_left_shift[14:0],ac_recdat};
						end
						
						else if(bit_count >= 6'd33 && bit_count <= 6'd48)
						begin
								rx_right_shift <= {rx_right_shift[14:0],ac_recdat};
						end
						
						if(bit_count == 6'd17)
						begin
								left_sample_buf <= rx_left_shift;
								audio_out_16b	 <= rx_left_shift;
						end
						
						if(bit_count == 6'd57)
						begin
								right_sample_buf <= rx_right_shift;
						end
				end
				
				if(clk_div == 4'd15)
				begin
						if(bit_count == 6'd63)
						begin
								bit_count <= 0;
								lrck_reg	 <= 0;
								tx_shift	 <= (playback_en)?{audio_in_16b}:left_sample_buf;
						end						
						
						else if(bit_count == 6'd31)
						begin
								bit_count <= bit_count + 1;
								lrck_reg <= 1;
								tx_shift <= (playback_en)?{audio_in_16b}:	right_sample_buf;
						end
						
						else
						begin
								bit_count <= bit_count + 1;
						end
				end
						
		end
		
		if (i2c_div == 7'd122) 
        begin
             i2c_div <= 7'd0;
                   
             case (rom_idx)
                  
						4'd0:  
                       rom_word <= {7'h0F, 9'b0_0000_0000}; // Reset
                  4'd1:
                       rom_word <= {7'h06, 9'b0_0011_0000}; // Power management
                  4'd2:
                       rom_word <= {7'h00, 9'b0_0001_0111}; // Left in vol (ADC)
                  4'd3:
                       rom_word <= {7'h01, 9'b0_0001_0111}; // Right in vol (ADC)
                  4'd4:
                       rom_word <= {7'h02, 9'b0_0111_1001}; // Left out vol (DAC 0 dB)
                  4'd5:
                       rom_word <= {7'h03, 9'b0_0111_1001}; // Right out vol (DAC 0 dB)
                  4'd6:  
                       rom_word <= {7'h04, 9'b0_0001_0010}; // Analog audio path (ADC = enable/DAC = enabled )
                  4'd7:
                       rom_word <= {7'h05, 9'b0_0000_0000}; // Digital audio path
                  4'd8:
                       rom_word <= {7'h07, 9'b0_0000_0010}; // Digital audio interface (I2S, 16-bit)
                  4'd9:
                       rom_word <= {7'h08, 9'b0_0000_0001}; // Sampling rate (48 kHz)
                  4'd10: 
                        rom_word <= {7'h09, 9'b0_0000_0001}; // Active core
                  4'd11:
                        rom_word <= {7'h06, 9'b0_0010_0000}; // Power management (Turn on output power)
						4'd12: 
								rom_word <= {7'h10, 9'b1_1000_1011}; // Automatic level controller 1
						4'd13: 
								rom_word <= {7'h11, 9'b0_0011_0010}; // Automatic level conroller 2	
						4'd14: 
								rom_word <= {7'h12, 9'b0_0000_1011}; // Noise Gate		
								
                  default: rom_word <= 16'h0000;
						
             endcase
				 
				 case(state)
						
						IDLE:
						begin
								ac_scl  <= 1;
								sda_out <= 1;
								
								if(gap_timer < 16'd5000)
								begin
										gap_timer <= gap_timer + 1;
								end
								
								if(rom_idx < TOTAL_REGS)
								begin
									   shift_buf     <= {8'h34, rom_word[15:8], rom_word[7:0]};
										i2c_bit_count <= 6'd0;
										state         <= START;
								end
								
								else
								begin
										state <= DONE;
								end
						end
						
						START:
						begin
								sda_out <= 0;
								state	  <= BIT_LOW;
						end
						
						BIT_LOW:
						begin
								ac_scl <= 1'b0;
                          
								if (i2c_bit_count == 6'd8 || i2c_bit_count == 6'd17 || i2c_bit_count == 6'd26)
								begin
										sda_out <= 1'b1;
								end      
                      
								else
								begin
										sda_out <= shift_buf[23];
								end     
                        
								state <= BIT_HIGH;
						end
						
						BIT_HIGH:
						begin
								ac_scl <= 1'b1;
                        
								if (i2c_bit_count != 6'd8 && i2c_bit_count != 6'd17 && i2c_bit_count != 6'd26)
								begin
										shift_buf <= {shift_buf[22:0], 1'b0};
								end     

								if (i2c_bit_count == 6'd26) 
								begin
										state   <= STOP_LOW;
								end 
									 
								else 
								begin
										i2c_bit_count <= i2c_bit_count + 1'b1;
										state         <= BIT_LOW;
								end
						end
						
						STOP_LOW:
						begin
								ac_scl  <= 1'b0;
								sda_out <= 1'b0;
								state   <= STOP_HIGH_SCL;
						end
						
						STOP_HIGH_SCL:
						begin
								ac_scl  <= 1'b1;
								sda_out <= 1'b0;
								state   <= STOP_HIGH_SDA;
						end
						
						STOP_HIGH_SDA:
						begin 
								ac_scl  <= 1'b1;
								sda_out <= 1'b1;
								rom_idx <= rom_idx + 1'b1;
								state   <= GAP;
						end
						
						GAP:
						begin
								if (gap_timer == 16'd600) 
								begin
										gap_timer <= 16'd0;
										state     <= IDLE;
								end 
                          
								else 
								begin
										gap_timer <= gap_timer + 1'b1;
								end
						
						end
						
						DONE:
						begin
								ac_scl  <= 1;
								sda_out <= 1;
						end
				 endcase
		end		 
		
		else
		begin
				i2c_div <= i2c_div + 1;
		end
end			
			
endmodule 
