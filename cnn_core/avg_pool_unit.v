module avg_pool_unit(
  input signed [31:0] layer2,
  input clk,
  input rst,
  input enable,
  output reg signed [31:0] avg
);

reg signed [31:0] stage1;
reg signed [31:0] stage2;
reg signed [31:0] stage3;
reg signed [31:0] stage4;

always @ (posedge clk or rst) begin
  stage1 <= 31'd0;
  stage2 <= 31'd0;
  stage3 <= 31'd0;
  stage4 <= 31'd0;

  if (rst) begin
    stage1 = 31'd0;
    done = 0;
  end else if(enable) begin
    stage1 <= layer2;
  end
end

always @ (posedge clk or rst) begin
  if (rst) begin
    stage2 <= 0;
  end else begin
    stage2 <= stage1 + stage2;
  end
end

always @ (posedge clk or rst) begin
  if (rst) begin
    stage3 <= 0;
  end else begin
    stage3 <= stage3 + stage2;
  end
end

always @ (posedge clk or rst) begin
  if (rst) begin
    stage4 <= 0;
  end else begin
    stage4 <= stage4 + stage3;
  end
end

always @ (posedge clk or rst) begin
  if (rst) begin
    avg <= 0;
  end else begin
    avg <= stage4 >> 2;
  end
  $display("Average Pooling output: %d at time %t", avg, $time);
end
endmodule