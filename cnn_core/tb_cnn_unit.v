`timescale 1ns/1ps

module tb_cnn_unit;

//parameters
parameter img_size = 64;
parameter out_width = 32;

//dut signals
reg clk;
reg rst;
reg enable;
reg [31:0] input_img [0:63];
wire [out_width-1:0] value;
wire done;

//instantiating the cnn core
cnn_top dut(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .input_img(input_img),
    .value(value),
    .done(done)
);

initial clk = 0;
always #5 clk = ~clk;

reg [31:0] test_image [0:img_size-1];
integer i;

initial begin
  for (i = 0; i < img_size; i = i + 1)begin
    test_image[i] = 32'd1;
  end
  #10;
  rst = 1;
  enable = 0;
  #20;
  rst = 0;
  for(i = 0; i < img_size; i = i + 1)begin
    input_img[i] = test_image[i];
  end
  #10;
  enable = 1;
  #10;
  enable = 0;
  wait(done == 1);
  $display("CNN prediction output: %d", value);
  #20;
  $finish;
end
endmodule