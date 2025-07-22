`timescale 1ns/1ps

module tb_gpio;

//dut signals
reg clk;
reg rst;
wire led1;
wire led2;
wire led3;
wire led4;
wire led_done;

//instantiation of gpio module
gpio_module dut(
    .clk(clk),
    .rst(rst),
    .led1(led1),
    .led2(led2),
    .led3(led3),
    .led4(led4),
    .led_done(led_done)
);

initial clk = 0;
forever #5 clk = ~clk;

reg [3:0] led_in;
integer i;

initial begin
  rst = 1;
  #10;
  rst = 0;
  #1000;
  $display("led1: %b, led2: %b, led3: %b, led4: %b", led1, led2, led3, led4);
  $stop;
end
endmodule