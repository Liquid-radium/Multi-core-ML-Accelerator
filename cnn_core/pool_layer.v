module pool_layer(
    input clk,
    input rst,
    input start,
    input signed [31:0] input_fm [0:35],
    output reg done,
    output reg signed [31:0] output_fm [0:8]
);

parameter fm_width = 6;
parameter fm_height = 6;

reg signed [31:0] line_buffer1 [0:1][0:5];

localparam IDLE1 = 4'b0000,
           LOAD1 = 4'b0001,
           SHIFT1 = 4'b0010,
           AVG_POOL_RESET1 = 4'b0011,
           AVG_POOL_FEED1 = 4'b0100,
           AVG_POOL_WAIT1 = 4'b0101,
           WRITE1 = 4'b0110,
           NEXT1 = 4'b0111,
           DONE1 = 4'b1000;

reg [1:0] avg_pool_count; //stores the number of mac inputs multiplied and accumulated (4, hence 2 bits)
reg [2:0] row1, col1;
reg [5:0] fm_address;
reg [3:0] latency_counter1;
reg [3:0] state1;
integer i;

//parameters for instantiation
reg signed [31:0] avg_pool_ip;
reg signed avg_pool_en;
reg signed avg_pool_rst;
reg signed [31:0] avg_pool_op;

avg_pool_unit avg_pool(
    .layer2(avg_pool_ip),
    .rst(avg_pool_rst),
    .enable(avg_pool_en),
    .clk(clk),
    .avg(avg_pool_op)
);

always @ (posedge clk) begin
  if(rst) begin
    state1 <= IDLE1;
    row1 <= 0;
    col1 <= 0;
    latency_counter1 <= 0;
  end else if (~rst) begin
    case(state1)
    IDLE1: begin
    if(start) begin
      row1 <= 0;
      col1 <= 0;
      latency_counter1 <= 0;
      state1 <= AVG_POOL_RESET;
    end 
    end
    LOAD1: begin
      line_buffer[0][fm_address % fm_width] <= input_fm[fm_address]; //to get the first pixel to convolve in that row
      if((fm_address + 1) % fm_width == 0) begin //if end of row
        line_buffer[1] <= line_buffer[0]; //used for maintaining the order of convolution in the image
      end
      if((fm_address + 1) == (fm_width * 2)) begin //if end of line buffer block
        state1 <= SHIFT1;
      end
      fm_address <= fm_address + 1;
    end
    SHIFT1: begin
      row1 <= 0;
      col1 <= 0;
      state1 <= AVG_POOL_RESET1;
    end
    AVG_POOL_RESET1: begin
      avg_pool_rst <= 1;
      avg_pool_en <= 0;
      avg_pool_count <= 0;
      latency_counter1 <= 0;
      state1 <= AVG_POOL_FEED1;
    end
    AVG_POOL_FEED1: begin
      avg_pool_en <= 1;
      avg_pool_rst <= 0;
      case(avg_pool_count) 
        0: avg_pool_ip <= line_buffer[0][col1];
        1: avg_pool_ip <= line_buffer[0][col1+1];
        2: avg_pool_ip <= line_buffer[1][col1];
        3: avg_pool_ip <= line_buffer[1][col1+1];
      endcase
      avg_pool_count <= avg_pool_count + 1;
      if(avg_pool_count == 4) begin
        avg_pool_en <= 0;
        latency_counter1 <= 0;
        state1 <= AVG_POOL_WAIT1;
      end
    end
    AVG_POOL_WAIT1: begin
      latency_counter1 <= latency_counter1 + 1;
      if(latency_counter1 == 3)begin
        latency_counter1 <= 0;
        state1 <= WRITE1;
      end
    end
    WRITE1: begin
      output_fm[(row1/2)*(fm_width/2) + (col1/2)] <= avg_pool_op;
      state1 <= NEXT1;
    end
    NEXT1: begin
    if (col1 < fm_width - 2) begin // if not last col1umn
        col1 <= col1 + 2;
        state1 <= AVG_POOL_RESET1;
    end 
    else if (row1 < fm_height - 2) begin // if not last row1
        col1 <= 0;
        row1 <= row1 + 2;
        line_buffer[0] <= line_buffer[1];
        for (i = 0; i < fm_width; i = i + 1) begin
        line_buffer[1][i] <= input_fm[(row1 + 2) * fm_width + i];
        end
        state1 <= AVG_POOL_RESET1;
    end 
    else begin
        state1 <= DONE1;
    end
    end
    DONE1: begin
          done <= 1;
      end
    endcase
  end
end
endmodule