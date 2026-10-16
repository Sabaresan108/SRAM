module SRAM_WR(input clk,rst,wr_req,
               input [17:0] wr_addr,
               input [15:0] wr_data,
               input [1:0] wr_byte_en,
               inout [15:0] sram_data,
               output reg [17:0] sram_addr,
               output reg sram_ce,
               output reg sram_oe,
               output reg sram_we,
               output reg sram_ub,
               output reg sram_lb,
               output reg wr_done);
 
reg [15:0] data_out;               
reg [1:0] state;    
reg d_oe;

assign sram_data =(d_oe)? data_out : 16'hz;

parameter
         IDLE  = 2'b00,
         SETUP = 2'b01,         
         WRITE = 2'b10,
         DONE  = 2'b11;
         
always @(posedge clk)
begin
     if(~rst)
     begin
          state     <= IDLE;
          sram_addr <= 0;
          d_oe      <= 0;
          data_out  <= 0;
          wr_done   <= 0;
          sram_ce   <= 1;
          sram_oe   <= 1;
          sram_we   <= 1;
          sram_ub   <= 1;         
          sram_lb   <= 1;          
     end
     
     else
     begin
                    
          case(state)
                IDLE:
                begin
                     sram_ce <= 1;
                     sram_oe <= 1;
                     sram_we <= 1;
                     sram_ub <= 1;
                     sram_lb <= 1;
                     d_oe    <= 0;
							wr_done <= 0;
                     
                     if (wr_req)
                     begin
                          sram_addr <= wr_addr;
                          data_out  <= wr_data;
                          d_oe      <= 1;
                          sram_ce   <= 0;
                          sram_oe   <= 1;
                          sram_we   <= 1;
                          sram_ub   <= ~ wr_byte_en[1];
                          sram_lb   <= ~ wr_byte_en[0];
                          
                          state     <= SETUP;
                     end
                end
                
                SETUP:
                begin
                     sram_we <= 0;
                     
                     state   <= WRITE;  
                end
                
                WRITE:
                begin
                     sram_we <= 1;
                     
                     state   <= DONE;
                end
                
                DONE:
                begin
                     sram_ce <= 1;
                     sram_ub <= 1;
                     sram_lb <= 1;
                     wr_done <= 1;
                     d_oe    <= 0;
                     
							if (~wr_req)
							begin
								  wr_done <= 0;
								  state 	 <= IDLE;
							end
							
							else
							begin
								  state <= DONE;
							end	
                end
                
                default : state <= IDLE;
          endcase  
     end
end         
endmodule
