module fc_layer(
    input clk,
    input enable,
    input rst,
    input signed [32*8-1:0] fc_input,
    output reg done,
    output reg signed [31:0] fc_layer_op
);

reg signed [31:0] fc_weights [0:8];
reg signed [31:0] fc_output;
reg signed [31:0] bias;
integer i;

always @ (posedge clk or rst) begin
  if (rst) begin
    fc_output <= 32'd0;
  end 
  else if(enable) begin
    for (i = 0; i < 9; i = i + 1) begin
      fc_output = fc_output + fc_input[i] * fc_weights[i];
    end
    fc_layer_op <= fc_output + bias;
    done <= 1;
  end 
  else begin
    done <= 0;
  end 
end
endmodule