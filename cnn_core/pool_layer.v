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

reg [1:0] avg_pool_count; //stores the number of inputs operated on (4, hence 2 bits)
reg [2:0] row, col;
reg [5:0] fm_address;
reg [3:0] latency_counter;
reg [3:0] state;
reg avg_pool_done;
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
    row = 3'b000;
    col = 3'b000;
    latency_counter = 4'b0000;
    fm_address = 6'b000000;
    avg_pool_count = 2'b00;
    avg_pool_ip = 32'd0;
    avg_pool_en = 0;
  end else begin
    case(state)
    IDLE: begin
    if(start) begin
      $display("value of start signal at time %t is %b", $time, start);
      done <= 0;
      row <= 3'b000;
      col <= 3'b000;
      latency_counter <= 4'b0000;
      state <= LOAD;
    end 
    end
    LOAD: begin
      line_buffer[0][fm_address % fm_width] <= input_fm[fm_address]; //to get the first pixel to convolve in that row
      $display("Loading input_fm[%0d] = %d into line_buffer[0][%0d] at time %t", fm_address, input_fm[fm_address], fm_address % fm_width, $time);
      if((fm_address + 1) % fm_width == 0) begin //if end of row
        line_buffer[1] <= line_buffer[0]; //used for maintaining the order of convolution in the image
      end
      if((fm_address + 1) == (fm_width * 2)) begin //if end of line buffer block
        state <= SHIFT;
      end
      fm_address <= fm_address + 1;
      $display("fm_address incremented to %0d at time %t", fm_address, $time);
    end
    SHIFT: begin
      row <= 0;
      col <= 0;
      state <= AVG_POOL_RESET;
      $display("Shifting line buffer at time %t", $time);
    end
    AVG_POOL_RESET: begin
      avg_pool_rst <= 1;
      avg_pool_en <= 0;
      avg_pool_count <= 2'b00;
      latency_counter <= 4'b0000;
      state <= AVG_POOL_FEED;
      $display("Resetting avg_pool unit at time %t", $time);
    end
    AVG_POOL_FEED: begin
    avg_pool_en <= 1;
    avg_pool_rst <= 0;

    case(avg_pool_count) 
      2'b00: begin 
        avg_pool_ip <= line_buffer[0][col];
        $display("Feeding avg_pool unit with input %d at time %t", avg_pool_ip, $time);
      end
      2'b01: avg_pool_ip <= line_buffer[0][col+1];
      2'b10: avg_pool_ip <= line_buffer[1][col];
      2'b11: avg_pool_ip <= line_buffer[1][col+1];
    endcase
    $display("Feeding avg_pool unit with input %d at time %t", avg_pool_ip, $time);
    avg_pool_count <= avg_pool_count + 1;
    $display("avg_pool_count: %d at time %t", avg_pool_count, $time);
    if (avg_pool_count == 2'b11) begin
      // Wait for next clock to send last input before disabling
      state <= AVG_POOL_WAIT;
    end

  end
    AVG_POOL_WAIT: begin
    avg_pool_en <= 0; // stop feeding after previous state sent last input
    latency_counter <= latency_counter + 1;

    if(latency_counter == 4) begin
      latency_counter <= 0;
      state <= WRITE;
    end
    $display("Waiting for avg_pool output at time %t", $time);
    end
    WRITE: begin
      output_fm[(row >> 1)*(fm_width >> 1) + (col >> 1)] <= avg_pool_op;
      $display("Writing output %d to output_fm[%0d] at time %t", 
                avg_pool_op, (row >> 1)*(fm_width >> 1) + (col >> 1), $time);
      state <= NEXT;
      $display("moving to next state NEXT at time %t", $time);
    end
    NEXT: begin
    if (col + 2 < fm_width) begin
      col <= col + 2;
      $display("Moving to next column: %d at time %t", col, $time);
    end else begin
      //col <= 0;
      if (row + 2 < fm_height) begin
        row <= row + 2;
        col <= 0;
        $display("Moving to next row: %d at time %t", row, $time);
      end else begin
        done <= 1;
        state <= IDLE;
      end
    end
    state <= AVG_POOL_RESET; // or back to LOAD, depending on design
    end
    DONE: begin
        //holds done signal 
      end
    endcase
  end
end
endmodule