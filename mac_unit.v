module mac_unit(
    input signed [15:0] a,
    input signed [15:0] b,
    input rst,
    input clk,
    input enable,
    output reg signed [31:0] acc
);

localparam signed [31:0] max_val = 32'sd2147483647;
localparam signed [31:0] min_val = -32'sd2147483648;

reg signed [31:0] stage1_op;
reg signed [15:0] stage2_op;
reg signed [31:0] stage3_op;

always @ (posedge clk) begin
  if (rst) begin
    stage1_op <= 32'sd0;
  end
  else if (enable) begin
    stage1_op <= a * b;
  end
end

always @ (posedge clk) begin
  if (rst) begin
    stage2_op <= 32'sd0;
  end
  else begin
    stage2_op <= [23:8]stage1_op;
  end
end

always @ (posedge clk) begin
  if (rst) begin
    stage3_op <= 32'sd0;
  end
  else begin
    stage3_op <= stage3_op + stage2_op;
    if (stage3_op > max_val) begin
      stage3_op <= max_val;
    end
    else if(stage3_op < min_val) begin
      stage3_op <= min_val;
    end
  end
end

always @ (posedge clk) begin
  if (rst) begin
    acc <= 32'sd0;;
  end 
  else begin
    acc <= stage3_op;
  end   
end

endmodule
