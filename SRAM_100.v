module SRAM_100(input clk,
					 input  [9:0] SW, // Red LED for read and data
					 output [9:0] LEDR, // Green LED for Write status
					 output	LEDG,
					 output [17:0] sram_addr,
					 inout  [15:0] sram_data,
					 output sram_ce,
					 output sram_oe,
					 output sram_we,
					 output sram_ub,
					 output sram_lb );
					 
reg [2:0]  state;
reg [6:0]  count;
reg [19:0] count_delay;
reg [23:0] blink_time;
reg [8:0]  prev_sw;
reg [7:0]  display_leds;

reg wr_req;
reg rd_req;
wire wr_done;
wire rd_done;

// READ and WRITE default pins
wire [17:0] wr_addr;
wire [17:0] rd_addr;
wire [15:0] wr_data;
wire [15:0] rd_data;

wire [17:0] wr_sram_addr;
wire wr_we;
wire wr_oe;
wire wr_ce;
wire wr_ub;
wire wr_lb;

wire [17:0] rd_sram_addr;
wire rd_we;
wire rd_oe;
wire rd_ce;
wire rd_ub;
wire rd_lb;

//SWITCH  
wire rst 			 = SW[9];
wire rw_mode 		 = SW[8];
wire [7:0] addr_sw = SW[7:0];

assign rd_addr = {10'b0,addr_sw};
assign wr_addr = {11'b0, count};
assign wr_data = 16'd100 - {9'b0,count};

wire [1:0]  wr_byte_en = 2'b11;
wire [1:0]  rd_byte_en = 2'b11;
	 
SRAM_WR writing (clk,rst,wr_req,wr_addr,wr_data,wr_byte_en,sram_data,wr_sram_addr,wr_ce,wr_oe,wr_we,wr_ub,wr_lb,wr_done);

SRAM_RD reading (clk,rst,rd_req,rd_addr,rd_byte_en,sram_data,rd_sram_addr,rd_data,rd_ce,rd_oe,rd_we,rd_ub,rd_lb,rd_done);


parameter
			IDLE  	  = 3'b000,
			WRITE      = 3'b001,
			WRITE_WAIT = 3'b010,
			DELAY      = 3'b011,
			DONE       = 3'b100;
			
always @(posedge clk)
begin
		if(~rst)
		begin
			   state 		 <= IDLE;
				count 		 <= 0;
				count_delay  <= 0;
				blink_time	 <= 0;
				wr_req		 <= 0;
				rd_req		 <= 0;
				prev_sw		 <= 0;
				display_leds <= 0;
		end
		
		else
		begin
				blink_time <= blink_time + 1;
				prev_sw 	  <= SW[8:0];
				
				if(!rw_mode)
				begin
						if((SW[7:0]!= prev_sw[7:0]) || (prev_sw[8] ==1))
						begin
								rd_req <= 1;
						end
				end
							  
				if(rd_done)
				begin
						rd_req <= 0;
						display_leds <= rd_data[7:0]; 
				end
				
				case(state)
					  
					  IDLE:
					  begin
							  if(rw_mode && !prev_sw[8])
							  begin
									  count <= 0;
									  state <= WRITE;
							  end					  
					  end
					  
					  WRITE:
					  begin
							  wr_req <= 1;
							  state	<= WRITE_WAIT;							  
					  end
					  
					  WRITE_WAIT:
					  begin
							  if(wr_done)
							  begin
									  wr_req <= 0;
									  state  <= DELAY;
							  end
					  end
					  
					  DELAY:
					  begin
							  if(count_delay == 20'd500_000)
							  begin
									  count_delay <= 0;
									  
									  if (count == 7'd100)
									  begin
											  state <= DONE;
									  end
									  
									  else
									  begin
											  count <= count + 1;
											  state <= WRITE;
									  end
							  end

							  else
							  begin
									  count_delay <= count_delay + 1;
							  end
	  
					  end
					  
					  DONE:
					  begin
							  if(!rw_mode)
							  begin
									  if(rw_mode && !prev_sw[8])
									  begin
											  state <= WRITE;
											  count <= 0;
									  end
							  end	  
					  end
					  
				endcase
		end
end	

//LED
assign LEDR [7:0] = display_leds;
assign LEDR [8] 	= 0;
assign LEDR [9] 	= rw_mode;
assign LEDG  = (state == DONE)? 1'b1 : (state != IDLE) ? blink_time [22] :1'b0;
					 
wire wr_active = ~wr_ce;
assign sram_addr = (wr_active)? wr_sram_addr : rd_sram_addr;

assign sram_ce = wr_ce & rd_ce;
assign sram_oe = (wr_active)? wr_oe : rd_oe;
assign sram_we = (wr_active)? wr_we : rd_we;
assign sram_ub = (wr_active)? wr_ub : rd_ub;
assign sram_lb = (wr_active)? wr_lb : rd_lb;					 
endmodule
