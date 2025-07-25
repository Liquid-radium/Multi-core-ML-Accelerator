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

reg signed [31:0] line_buffer [0:1][0:5];

localparam IDLE = 4'b0000,
           LOAD = 4'b0001,
           SHIFT = 4'b0010,
           AVG_POOL_RESET = 4'b0011,
           AVG_POOL_FEED = 4'b0100,
           AVG_POOL_WAIT = 4'b0101,
           WRITE = 4'b0110,
           NEXT = 4'b0111,
           DONE = 4'b1000;

reg [1:0] avg_pool_count; //stores the number of mac inputs multiplied and accumulated (4, hence 2 bits)
reg [2:0] row, col;
reg [5:0] fm_address;
reg [3:0] latency_counter;
reg [3:0] state;
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
    state = IDLE;
    row = 0;
    col = 0;
    latency_counter = 0;
  end else begin
    case(state)
    IDLE: begin
    if(start) begin
      row <= 0;
      col <= 0;
      latency_counter <= 0;
      state <= AVG_POOL_RESET;
    end 
    end
    LOAD: begin
      line_buffer[0][fm_address % fm_width] <= input_fm[fm_address]; //to get the first pixel to convolve in that row
      if((fm_address + 1) % fm_width == 0) begin //if end of row
        line_buffer[1] <= line_buffer[0]; //used for maintaining the order of convolution in the image
      end
      if((fm_address + 1) == (fm_width * 2)) begin //if end of line buffer block
        state <= SHIFT;
      end
      fm_address <= fm_address + 1;
    end
    SHIFT: begin
      row <= 0;
      col <= 0;
      state <= AVG_POOL_RESET;
    end
    AVG_POOL_RESET: begin
      avg_pool_rst <= 1;
      avg_pool_en <= 0;
      avg_pool_count <= 0;
      latency_counter <= 0;
      state <= AVG_POOL_FEED;
    end
    AVG_POOL_FEED: begin
      avg_pool_en <= 1;
      avg_pool_rst <= 0;
      case(avg_pool_count) 
        0: avg_pool_ip <= line_buffer[0][col];
        1: avg_pool_ip <= line_buffer[0][col+1];
        2: avg_pool_ip <= line_buffer[1][col];
        3: avg_pool_ip <= line_buffer[1][col+1];
      endcase
      avg_pool_count <= avg_pool_count + 1;
      if(avg_pool_count == 4) begin
        avg_pool_en <= 0;
        latency_counter <= 0;
        state <= AVG_POOL_WAIT;
      end
    end
    AVG_POOL_WAIT: begin
      latency_counter <= latency_counter + 1;
      if(latency_counter == 3)begin
        latency_counter <= 0;
        state <= WRITE;
      end
    end
    WRITE: begin
      output_fm[(row/2)*(fm_width/2) + (col/2)] <= avg_pool_op;
      state <= NEXT;
    end
    NEXT: begin
    if (col < fm_width - 2) begin // if not last column
        col <= col + 2;
        state <= AVG_POOL_RESET;
    end 
    else if (row < fm_height - 2) begin // if not last row
        col <= 0;
        row <= row + 2;
        line_buffer[0] <= line_buffer[1];
        for (i = 0; i < fm_width; i = i + 1) begin
        line_buffer[1][i] <= input_fm[(row + 2) * fm_width + i];
        end
        state <= AVG_POOL_RESET;
    end 
    else begin
        state <= DONE;
    end
    end
    DONE: begin
          done <= 1;
      end
    endcase
  end
end
endmodule