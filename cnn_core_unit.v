module cnn_top(
    input clk,
    input rst,
    input enable,
    input [7:0] input_img [0:63],
    output reg [15:0] value,
    output reg done
);

//registers needed for instantiation of cnn engine
reg cnn_start, pool_start, fc_start;
wire cnn_done, pool_done, fc_done;

//output wires needed for inter-layer connection
wire signed [7:0] conv_output [0:35];
wire signed [7:0] pool_output [0:8];
wire signed [15:0] fc_output;

//FSM states
localparam IDLE = 0,
           CNN_START = 1,
           CNN_WAIT = 2,
           POOL_START = 3,
           POOL_WAIT = 4,
           FC_START = 5,
           FC_WAIT = 6,
           DONE = 7;

reg [2:0] state;
reg done_reg;
assign done = done_reg;
assign value = fc_output;

//layer 1 : convolutional layer
cnn_engine conv_layer(
    .clk(clk),
    .rst(rst),
    .enable(conv_start),
    .input_ram(input_img),
    .done(cnn_done),
    .output_ram(conv_output)
);

//layer 2 : pool layer
pool_layer pool_layer(
    .clk(clk),
    .rst(rst),
    .enable(pool_start),
    .input_fm(conv_output),
    .done(pool_done),
    .output_fm(pool_output)
);

//layer 3 : fully connected layer
fc_layer fc_layer(
    .clk(clk),
    .rst(rst),
    .enable(fc_start),
    .fc_input(pool_output),
    .done(fc_done),
    .fc_layer_op(fc_output)
);

//FSM controller
always @ (posedge clk or rst) begin
  if (rst) begin
    cnn_start <= 0;
    pool_start <= 0;
    fc_start <= 0;
  end else if (enable) begin
    case(state) 
      IDLE: begin
        cnn_start <= 1;
        state <= CNN_START;
      end
      CNN_START: begin
        cnn_start <= 0;
        state <= CNN_WAIT;
      end
      CNN_WAIT: begin
        if(cnn_done) begin
          pool_start <= 1;
          state <= POOL_START;
        end
      end
      POOL_START: begin
        pool_start <= 0;
        state <= POOL_WAIT;
      end
      POOL_WAIT: begin
        if(pool_done) begin
          fc_start <= 1;
          state <= FC_START;
        end
      end
      FC_START: begin
        fc_start <= 0;
        state <= FC_WAIT;
      end
      FC_WAIT: begin
        if(fc_done) begin
          done_reg <= 1;
          state <= DONE;
        end
      end
      DONE: begin
        // hold done signal
      end
    endcase
  end
end
endmodule