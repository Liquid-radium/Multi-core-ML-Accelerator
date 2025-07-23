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
reg [out_width-1:0] value;
reg done;

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
  clk = 0;
  rst = 0;
  enable = 0;
 #10;
$display("Assigning test_image with all 1s...");
for (i = 0; i < img_size; i = i + 1) begin
  test_image[i] = 32'b00000000000000000000000000000001;
end

$display("Contents of test_image:");
for (i = 0; i < img_size; i = i + 1) begin
  $display("test_image[%0d] = %0d", i, test_image[i]);
end

#10;
rst = 1;
enable = 1;
#20;
rst = 0;

$display("Assigning test_image to input_img...");
for (i = 0; i < img_size; i = i + 1) begin
  input_img[i] = test_image[i];
end

$display("Contents of input_img:");
for (i = 0; i < img_size; i = i + 1) begin
  $display("input_img[%0d] = %0d", i, input_img[i]);
end

#10;
enable = 1;
#10;
// enable = 0;

integer timeout;
assign timeout = 0;
while (done !== 1 && timeout < 1000) begin
    #10;
    timeout = timeout + 1;
    $display("Time: %t | done: %b", $time, done);
end

if (done === 1) begin
    $display("CNN prediction output: %d", value);
end else begin
    $display("ERROR: Timeout waiting for done signal!");
end
$finish;
#20;
$display("CNN prediction output: %d", value);
#20;
$finish;
end
endmodule