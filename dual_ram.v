module dual_ram #(
    parameter addr_width = 32,
    data_width = 8
)(
    input clk,
    
    //uart port (port a)
    input we_a,
    input [addr_width-1:0] addr_a,
    input [data_width-1:0] data_a,
    output reg [data_width-1:0] mem_a,

    //cnn port (port b)
    input we_b,
    input [addr_width-1:0] addr_b,
    input [data_width-1:0] data_b,
    output reg [data_width-1:0] mem_b
);

reg [data_width-1:0] mem [0:addr_width -1];

always @ (posedge clk)begin
  if (we_a)begin
    mem[addr_a] <= data_a;
  end
  mem_a <= data_a;
end

always @ (posedge clk) begin
  if (we_b)begin
    mem[addr_b] <= data_b;
  end
  mem_b <= data_b;
end

endmodule
