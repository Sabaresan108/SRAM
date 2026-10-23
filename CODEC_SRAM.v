module CODEC_SRAM(input clk,
						input  [9:0] SW,
						output [9:0] LEDR,
						output [17:0] sram_addr,
						inout  [15:0] sram_data,
						output sram_ce,
						output sram_oe,
						output sram_we,
						output sram_ub,
						output sram_lb,
						input ac_recdat,
						output ac_bclk,
						output ac_mclk,
						output ac_pblrc,
						output ac_pbdat,
						output ac_reclrc,
						output ac_scl,
						inout ac_sda);
						
assign rst 		= SW[9];
assign rw_mode = ~SW[8];

wire [1:0] wr_byte_en = 2'b11;
wire [1:0] rd_byte_en = 2'b11;

wire sample_ready;
wire [15:0] live_audio;
wire [15:0] sram_read_data;

reg [17:0] address;
reg [17:0] max_address;
reg prev_rw_mode;

reg wr_req;
reg rd_req;


reg prev_wr_done;
reg prev_rd_done;

wire wr_done;
wire rd_done;

wire i2c_done;

wire playback_en = ~ rw_mode;

wire [17:0] rd_sram_addr;
wire rd_we;
wire rd_oe;
wire rd_ce;
wire rd_lb;
wire rd_ub;

wire [17:0] wr_sram_addr;
wire wr_we;
wire wr_oe;
wire wr_ce;
wire wr_lb;
wire wr_ub;

SRAM_WR writing (clk,rst,wr_req,address,live_audio,wr_byte_en,sram_data,wr_sram_addr,wr_ce,wr_oe,wr_we,wr_ub,wr_lb,wr_done);

SRAM_RD reading (clk,rst,rd_req,address,rd_byte_en,sram_data,rd_sram_addr,sram_read_data,rd_ce,rd_oe,rd_we,rd_ub,rd_lb,rd_done);

Audio_codec audio (clk,rst,ac_recdat,playback_en,ac_mclk,ac_bclk,ac_pblrc,ac_reclrc,ac_pbdat,ac_scl,ac_sda,sample_ready,sram_read_data,live_audio,i2c_done);
						

always @(posedge clk) 
begin
		prev_wr_done <= wr_done;
		prev_rd_done <= rd_done;
end

wire wr_done_pulse = wr_done && !prev_wr_done;
wire rd_done_pulse = rd_done && !prev_rd_done;						

always @(posedge clk)
begin
		if(~rst)
		begin
				prev_rw_mode <= 0; 
				wr_req 		 <= 0;
				rd_req 		 <= 0;
				address		 <= 0;
				max_address	 <= 0;
		end
		
		else
		begin
				prev_rw_mode <= rw_mode;
				
				if(prev_rw_mode == 1'b0 && rw_mode == 1'b1)
				begin
						max_address <= address;
				      address 		<= 0;
				end
				
				else if(prev_rw_mode == 1'b1 && rw_mode == 1'b0)
				begin
						address <= 0;
				end
				
				if (!i2c_done)
				begin
						address <= 18'd0;
						wr_req  <= 1'b0;
						rd_req  <= 1'b0;
				end
				
				if (sample_ready)
				begin
				      if(rw_mode)
				      begin
				            wr_req <= 1;
				      end
				      
				      else
				      begin
				            rd_req <= 1;
				      end
				end
				
				if(wr_done_pulse)
				begin
				      wr_req  <= 0;
				      address <= address + 1;
				end
				
				if(rd_done_pulse)
				begin
				      rd_req <= 0;
						
						if(address >= max_address && max_address != 18'd0)
						begin
								address <= 0;
						end
						
						else
						begin
								address <= address + 1;
						end
				end						
		end	
end

//LED

assign LEDR[0] = i2c_done;						 // DONE state
assign LEDR[9] = rst;             			// Glows when rst is toggled
assign LEDR[8] = ~rw_mode;                 // Mode indicator (1 = play/0 = rec)

wire wr_active   = ~wr_ce;
assign sram_addr =(wr_active)? wr_sram_addr : rd_sram_addr;

assign sram_ce = wr_ce & rd_ce;
assign sram_oe = (wr_active)? wr_oe : rd_oe;
assign sram_we = (wr_active)? wr_we : rd_we;
assign sram_ub = (wr_active)? wr_ub : rd_ub;
assign sram_lb = (wr_active)? wr_lb : rd_lb;
					
endmodule 
