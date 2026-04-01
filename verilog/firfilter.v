module basicfir #(
  parameter TAPS = 336,
  parameter DATA_WIDTH = 16,
  parameter TAP_WIDTH = 19,
  parameter INTER_WIDTH = 35                  
  ) (
     input                          clk, en,
     input signed [DATA_WIDTH-1:0]  input_data,
     output reg signed [DATA_WIDTH-1:0] output_data);

   reg signed [19:0]   taps [335:0];
   initial begin
     `include "taps.vh"
   end
   
   reg signed [DATA_WIDTH-1:0] buffers [TAPS-1:0];
   reg signed [INTER_WIDTH-1:0] acc;
   integer                      i;

   // buffer stage
   always @(posedge clk)
     if (en == 1'b1)
       begin
          for (i = 1; i < TAPS; i = i + 1) begin
             buffers[i] <= buffers[i-1];
          end
          buffers[0] <= input_data;
       end


   // multiply-accumulation stage
   always @(posedge clk)
     if (en == 1'b1)
       begin
          acc = 0;
          for (i = 0; i < TAPS; i = i + 1) begin
             acc = acc + buffers[i] * taps[i];
          end
          output_data <= acc >>> 19;
       end
   
endmodule // basicfir


module pipelinedfir #(
                      parameter TAPS = 336,
                      parameter DATA_WIDTH = 16,
                      parameter TAP_WIDTH = 19,
                      parameter INTER_WIDTH = 35                  
                      ) (
                         input                          clk, en,
                         input signed [DATA_WIDTH-1:0]  input_data,
                         output reg signed [DATA_WIDTH-1:0] output_data);


   reg signed [19:0]   taps [335:0];
   initial begin
     `include "taps.vh"
   end


   reg signed [INTER_WIDTH-1:0] buffers [TAPS-1:0];
   integer                      i;

   // multiply-accumulation stage
   always @(posedge clk)
     if (en == 1'b1)
       begin
          for (i = 0; i < TAPS-1; i = i + 1) begin
             buffers[i] <= buffers[i+1] + input_data * taps[i];
          end
          buffers[TAPS-1] <= input_data * taps[TAPS-1];
          output_data <= buffers[0] >>> 19;
       end
   
endmodule // pipelinedfir

module combinedfir #(
  parameter TAPS = 336,
  parameter DATA_WIDTH = 16,
  parameter TAP_WIDTH = 19,
  parameter INTER_WIDTH = 35                  
  ) (
     input                          clk, en,
     input signed [DATA_WIDTH-1:0]  input_data,
     output reg signed [DATA_WIDTH-1:0] output_data);

   reg signed [19:0]   taps [335:0];
   initial begin
     `include "taps.vh"
   end

   
   reg signed [INTER_WIDTH-1:0] buffers [TAPS-1:0];
   reg signed [DATA_WIDTH-1:0]  input_even;
   reg signed [DATA_WIDTH-1:0]  input_odd;
   reg signed [DATA_WIDTH-1:0]  output_even;
   reg signed [DATA_WIDTH-1:0]  output_odd;
   integer                      i;
   reg                          toggle, val;


   // get even and odd input data and merge output data
   always @(posedge clk)
     if (en == 1'b1)
       begin
          if (toggle == 1'b0)
            begin
               toggle = 1'b1;
               input_even <= input_data;
               output_data <= output_even;
               val = 1'b0;
            end
          else
            begin
               toggle = 1'b0;
               input_odd <= input_data;
               output_data <= output_odd;
               val = 1'b1;
            end
       end
   
   // multiply-accumulation stage
   always @(posedge clk)
     if (en == 1'b1 & val == 1'b1)
       begin
          // path 1
          for (i = 0; i < TAPS-2; i = i + 2) begin
             buffers[i] <= buffers[i+2] + input_even * taps[i] + input_odd * taps[i+1];
          end
          buffers[TAPS-1] <= input_data * taps[TAPS-1];
          output_odd <= buffers[0] >>> 19;

          // path 2
          for (i = 1; i < TAPS-2; i = i + 2) begin
             buffers[i] <= buffers[i+2] + input_odd * taps[i] + input_even * taps[i+1];
          end
          buffers[TAPS-1] <= input_data * taps[TAPS-1];
          output_even <= buffers[1] >>> 19;
       end 
   
endmodule // combinedfir
