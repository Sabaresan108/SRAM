module SRAM (input clk,rst,
				 output [17:0] sram_addr,
             inout  [15:0] sram_data,
             output sram_we,
				 output sram_oe,
				 output sram_ce,
				 output sram_ub,
				 output sram_lb);
				 
sram_issp uut (probe,source);			

wire [17:0] probe;
wire [57:0] source;
				  
wire wr_req;
wire rd_req;
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

// Sources	
assign wr_req 		= source [0];
assign rd_req 		= source [1];
assign wr_byte_en = source [3:2];
assign rd_byte_en = source [5:4];
assign rd_addr 	= source [23:6];
assign wr_addr 	= source [41:24];
assign wr_data 	= source [57:42];

//Probe
assign probe [0] 	  = wr_done;
assign probe [1] 	  = rd_done;
assign probe [17:2] = rd_data;

SRAM_WR writing (clk,rst,wr_req,wr_addr,wr_data,wr_byte_en,sram_data,wr_sram_addr,wr_ce,wr_oe,wr_we,wr_ub,wr_lb,wr_done);

SRAM_RD reading (clk,rst,rd_req,rd_addr,rd_byte_en,sram_data,rd_sram_addr,rd_data,rd_ce,rd_oe,rd_we,rd_ub,rd_lb,rd_done);

wire wr_active = ~wr_ce;

assign sram_addr =(wr_active)? wr_sram_addr : rd_sram_addr;

assign sram_ce = wr_ce & rd_ce;
assign sram_oe = (wr_active)? wr_oe : rd_oe;
assign sram_we = (wr_active)? wr_we : rd_we;
assign sram_ub = (wr_active)? wr_ub : rd_ub;
assign sram_lb = (wr_active)? wr_lb : rd_lb;
                
endmodule
