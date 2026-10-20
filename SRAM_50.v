module SRAM_50 (input  clk,
    					  input  [9:0] SW,
    					  output [9:0] LEDR,
    					  output [17:0] sram_addr,
    					  inout  [15:0] sram_data,
    					  output sram_we,
    					  output sram_oe,
    					  output sram_ce,
    					  output sram_ub,
    					  output sram_lb);
						
reg wr_req;
reg rd_req;
wire wr_done;
wire rd_done;
wire [17:0] wr_addr;
wire [17:0] rd_addr;
wire [15:0] wr_data;
wire [15:0] rd_data;
wire [1:0]  wr_byte_en;
wire [1:0]  rd_byte_en;				  
                
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

assign rd_byte_en = 2'b11;
assign rd_addr 	= target_addr;


sram_50_issp issp ( probe, source );
wire [17:0] probe;
wire [35:0] source;

// Sources	
assign wr_byte_en = source [1:0];
assign wr_addr 	= source [19:2];
assign wr_data 	= source [35:20];

//Probe
assign probe [0] 	  = wr_done;
assign probe [1] 	  = rd_done;
assign probe [17:2] = rd_data;

// Switch and LED	 
wire rst  	   = SW[9];   // Reset 
wire rw_mode   = SW[8];   // READ = 0/WRITE = 1  				 
wire [7:0] val = SW[7:0]; // Address/Data
				 
wire [17:0] target_addr = {10'b0,val};
				  
reg [8:0] prev_SW;
reg [7:0] display_leds;
			

SRAM_WR_50 writing (clk,rst,wr_req,wr_addr,wr_data,wr_byte_en,sram_data,wr_sram_addr,wr_ce,wr_oe,wr_we,wr_ub,wr_lb,wr_done);

SRAM_RD_50 reading (clk,rst,rd_req,rd_addr,rd_byte_en,sram_data,rd_sram_addr,rd_data,rd_ce,rd_oe,rd_we,rd_ub,rd_lb,rd_done);

always @(posedge clk)
begin
	  if(~rst)
	  begin
			 prev_SW 	  <= 0;
			 wr_req 		  <= 0;
			 rd_req 		  <= 0;
			 display_leds <= 0;
	  end 
	  
	  else
	  begin
	  		 prev_SW <= SW[8:0];
			 
			 if(rw_mode && !prev_SW[8])
			 begin
					wr_req <= 1;				
			 end
			 
			 if (!rw_mode && ((SW[7:0] != prev_SW[7:0]) || (prev_SW[8] == 1'b1)))
			 begin
					rd_req <= 1;
			 end
			 
			 if(wr_done)
			 begin
					wr_req <= 0;
			 end
			 
			 if(rd_done)
			 begin
					rd_req 		 <= 0;
					display_leds <= rd_data [7:0];
			 end
	  end	 
end

assign LEDR[7:0] = display_leds;
assign LEDR[8]   = 0;
assign LEDR[9]   = rw_mode;

wire wr_active = ~wr_ce;
assign sram_addr = (wr_active)? wr_sram_addr : rd_sram_addr;

assign sram_ce = wr_ce & rd_ce;
assign sram_oe = (wr_active)? wr_oe : rd_oe;
assign sram_we = (wr_active)? wr_we : rd_we;
assign sram_ub = (wr_active)? wr_ub : rd_ub;
assign sram_lb = (wr_active)? wr_lb : rd_lb;
                
endmodule

// Same read and write for this module
