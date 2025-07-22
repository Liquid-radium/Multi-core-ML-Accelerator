`timescale 1ns/1ps

module tb_cnn_multi;

//parameters
parameter img_size = 64;
parameter out_width = 32;
parameter n = 4;

//dut signals
reg clk;
reg rst;
reg [31:0] input_images [0:n-1][0:img_size-1];
wire [out_width-1:0] predictions[0 : n-1];
wire all_done;

//instantiation of module
multi_core dut(
    .clk(clk),
    .rst(rst),
    .input_images(input_images),
    .predictions(predictions),
    .all_done(all_done)
);

initial clk = 0;
always #5 clk = ~clk;

reg [31:0] test_images [0:n-1][0:img_size-1];
integer i;
integer j;

initial begin
  clk = 0;
  rst = 0;
  all_done = 0;
  #10;
  for (j = 0; j < n; j = j + 1)begin
    for(i = 0; i < img_size; i = i + 1)begin
        test_images[j][i] = 32'd1;
    end
  end
  #10;
  rst = 1;
  #20;
  rst = 0;
  for (j = 0; j < n; j = j + 1)begin
    for(i = 0; i < img_size; i = i + 1)begin
        input_images[j][i] = test_images[j][i];
    end
  end
  #30;
  wait(all_done == 1);
  //$display("CNN prediction output: %d", predictions);
  #20;
  $finish;
end
endmodule
