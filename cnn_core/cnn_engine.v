module cnn_engine(
    input clk,
    input rst, 
    input [31:0] input_ram [0:63], //stores the value of each pixel in the image
    input start,
    output reg done,
    output reg signed [31:0] output_ram [0:35]
);

parameter img_width = 8;
parameter img_height = 8;
integer i;

reg [31:0] line_buffer[0:2][0:7]; //stores 3 rows of the image (image line, therefore 8 columns * 3 rows)
reg [31:0] kernel[0:2][0:2]; //stores the kernel values

localparam IDLE       = 4'b0000,
           LOAD       = 4'b0001,
           SHIFT      = 4'b0010,
           MAC_RESET  = 4'b0011,
           MAC_FEED   = 4'b0100,
           MAC_WAIT   = 4'b0101,
           WRITE      = 4'b0110,
           NEXT       = 4'b0111,
           DONE       = 4'b1000;

reg [3:0] state; //stores the state number, 9 states in total
reg [2:0] row, col; //stores the value of the row and column (cols 1-6 in op, hance 3 bits) 
reg [5:0] img_address; //stores the serial number of the pixel as per the input ram (0-63, hence 6 bits)
reg [3:0] mac_count; //stores the number of mac inputs multiplied and accumulated (9, hence 4 bits)
reg [3:0] latency_counter; //counter for waiting for pipeline to flush (2 bits sufficient, 4 for deeper pipelines)

// mac parameters for instantiation
reg signed [31:0] mac_a;
reg signed [31:0] mac_b;
reg signed [31:0] mac_acc;
reg [31:0] relu_acc;
reg mac_en;
reg mac_rst;

mac_unit mac(
    .a(mac_a),
    .b(mac_b),
    .rst(mac_rst),
    .clk(clk),
    .enable(mac_en),
    .acc(mac_acc)
);

//relu paramaters for instantiation
relu_unit relu(
    .mac_acc(mac_acc),
    .relu_acc(relu_acc)
);

//initialising kernel values
initial begin
  kernel[0][0] = -1; kernel[0][1] = -1; kernel[0][2] = -1;
  kernel[1][0] =  0; kernel[1][1] =  0; kernel[1][2] =  0;
  kernel[2][0] =  1; kernel[2][1] =  1; kernel[2][2] =  1;
end

always@(posedge clk)begin
  if (rst) begin
    state <= 4'b0000;
    row <= 3'b000;
    col <= 3'b000;
    done <= 1'b0;
    mac_count <= 4'b0000;
    latency_counter <= 4'b0000;
    mac_en <= 1'b0;
    mac_rst <= 1'b0;
  end else if (~rst) begin
    case(state)
    IDLE: begin
      if (start) begin
        row <= 3'b000;
        col <= 3'b000;
        img_address <= 6'b000000;
        state <= 4'b0001;
      end
    end
    LOAD: begin
      line_buffer[0][img_address % img_width] <= input_ram[img_address]; //to get the first pixel to convolve in that row
      if((img_address + 1) % img_width == 0) begin //if end of row
        line_buffer[1] <= line_buffer[0]; //used for maintaining the order of convolution in the image
      end
      if((img_address + 1) == (img_width * 3)) begin //if end of line buffer block
        state <= 4'b0010;
      end
      img_address <= img_address + 1;
    end
    SHIFT: begin
      col <= 3'b001;
      row <= 3'b001;
      state <= 4'b0011;
    end
    MAC_RESET: begin
      mac_rst <= 1'b1;
      mac_en <= 1'b0;
      mac_count <= 4'b0000;
      latency_counter <= 4'b0000;
      state <= 4'b0100;
    end
    MAC_FEED: begin
      mac_rst <= 1'b0;
      mac_en <= 1'b1;
      case(mac_count) 
        0: begin mac_a <= line_buffer[0][col-1]; mac_b <= kernel[0][0]; end
        1: begin mac_a <= line_buffer[0][col];   mac_b <= kernel[0][1]; end
        2: begin mac_a <= line_buffer[0][col+1]; mac_b <= kernel[0][2]; end
        3: begin mac_a <= line_buffer[1][col-1]; mac_b <= kernel[1][0]; end
        4: begin mac_a <= line_buffer[1][col];   mac_b <= kernel[1][1]; end
        5: begin mac_a <= line_buffer[1][col+1]; mac_b <= kernel[1][2]; end
        6: begin mac_a <= line_buffer[2][col-1]; mac_b <= kernel[2][0]; end
        7: begin mac_a <= line_buffer[2][col];   mac_b <= kernel[2][1]; end
        8: begin mac_a <= line_buffer[2][col+1]; mac_b <= kernel[2][2]; end
      endcase
      mac_count <= mac_count + 1;
      if(mac_count == 4'b1001) begin
        mac_en <= 1'b0;
        latency_counter <= 4'b0000;
        state <= 4'b0101;
      end
    end
    MAC_WAIT: begin
      latency_counter <= latency_counter + 1;
      if (latency_counter == 4'b0011)begin
        latency_counter <= 4'b0000;
        state <= 4'b0110;
      end
      //state <= 4'b0110; //wait for 3 clock cycles for mac to finish
    end
    WRITE: begin
      output_ram[(row -1)*(img_width -2) + (col -1)] <= relu_acc;
      state <= 4'b0111;
    end
    NEXT: begin
      if (col < img_width - 2) begin //if last column not reached
        col <= col + 1;
        state <= 4'b0100; //go back to MAC feed
    end else if (row < img_height - 2) begin //last column reached but not last row
      col <= 1;
      row <= row + 1;
      line_buffer[0] <= line_buffer[1];
      line_buffer[1] <= line_buffer[2];
      for (i = 0; i < img_width; i = i +1)
        line_buffer[2][i] <= input_ram[(row + 2)*img_width + i];
        state <= 4'b0011; //go back to MAC reset
      end 
      else begin
        state <= 4'b1000; //all rows and columns processed
      end 
    end
    DONE: begin
      done <= 1'b1;
      $display("DONE state reached at time %t", $time);
    end
    end
    endcase
  end
end
endmodule