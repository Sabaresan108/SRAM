module SRAM_RD(input clk,rst,rd_req,
               input [17:0] rd_addr,
               input [1:0] rd_byte_en,
               inout [15:0] sram_data,
               output reg [17:0] sram_addr,
               output reg [15:0] rd_data,
               output reg sram_ce,
               output reg sram_oe,
               output reg sram_we,
               output reg sram_ub,
               output reg sram_lb,               
               output reg rd_done);
 
reg [1:0] state;    

parameter
         IDLE  = 2'b00,
         SETUP = 2'b01,         
         READ = 2'b10,
         DONE  = 2'b11;
         
always @(posedge clk)
begin
     if(~rst)
     begin
          state     <= IDLE;
          sram_addr <= 0;
          rd_data   <= 0;
          rd_done   <= 0;
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
							rd_done <= 0;

                     
                     if (rd_req)
                     begin
                          sram_addr <= rd_addr;
                          sram_ce   <= 0;
                          sram_oe   <= 0;
                          sram_we   <= 1;
                          sram_ub   <= ~ rd_byte_en[1];
                          sram_lb   <= ~ rd_byte_en[0];
                          
                          state     <= SETUP;
                     end
                end
                
                SETUP:
                begin
                     state   <= READ;  
                end
                
                READ:
                begin
                     rd_data <= sram_data;
                     sram_ce <= 1;
                     sram_ub <= 1;
                     sram_lb <= 1;
                     rd_done <= 1;
                     sram_oe <= 1;
                     
                     state   <= DONE;
                end
                
                DONE:
                begin                    
							rd_done <= 1;							
							
							if (~rd_req)
							begin
								 rd_done <= 0;
								 state 	<= IDLE;
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

