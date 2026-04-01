module testbench();
   reg clk = 0;
   reg en = 0;
   reg signed [15:0] data_in;
   wire signed [15:0] data_out;
   
   basicfir uut (
                   .clk(clk),
                   .en(en),
                   .data_in(data_in),
                   .data_out(data_out)
                   );

   always #5 clk = ~clk;

   initial begin
      #20 rst = 1;
      
      data_in = 1000;
      #10 data_in = 2000;
      #10 data_in = -1000;
      #100 $stop;
   end
   
endmodule // testbench
