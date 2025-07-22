`timescale 1ns/1ps

module tb_min;
  reg clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $monitor("Time = %0t : clk = %b", $time, clk);
    #50 $finish;
  end
endmodule
