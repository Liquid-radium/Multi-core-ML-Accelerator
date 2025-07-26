module fc_layer(
    input clk,
    input enable,
    input rst,
    input signed [31:0] fc_input [0:8],
    output reg done,
    output reg signed [31:0] fc_layer_op
);

reg signed [31:0] fc_weights [0:8];
reg signed [31:0] fc_output;
reg signed [31:0] bias;
integer i;
reg [31:0] relu_acc;

initial begin
  // Initialize weights and bias for the fully connected layer
  fc_weights[0] = 32'sd1;
  fc_weights[1] = 32'sd1;
  fc_weights[2] = 32'sd1;
  fc_weights[3] = 32'sd1;
  fc_weights[4] = 32'sd1;
  fc_weights[5] = 32'sd1;
  fc_weights[6] = 32'sd1;
  fc_weights[7] = 32'sd1;
  fc_weights[8] = 32'sd1;

  bias = 32'sd0; // Bias can be set to any value, here we use zero
end

relu_unit relu(
    .fc_op(fc_output),
    .relu_acc(fc_layer_op)
);

always @ (posedge clk) begin
  if (rst) begin
      fc_output = 32'd0;
      done = 0; 
  end 
  else begin
  if(enable) begin
    fc_output = 32'd0; // Reset output for new computation
    done = 0; // Reset done signal
    $display("Starting FC Layer computation at time %t", $time);
    // Perform the fully connected layer operation
    for (i = 0; i < 9; i = i + 1) begin
      fc_output = fc_output + fc_input[i] * fc_weights[i];
      $display("Multiplying input %d with weight %d, current output: %d", fc_input[i], fc_weights[i], fc_output);
    end
    fc_layer_op <= fc_output + bias;
    done <= 1;
    $display("FC Layer output: %d at time %t", relu_acc, $time);
  end
end
end 
endmodule