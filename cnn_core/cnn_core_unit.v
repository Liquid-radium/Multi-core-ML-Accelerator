module cnn_top(
    input clk,
    input rst,
    input enable,
    input [31:0] input_img [0:63],
    output reg [31:0] value,
    output reg done
);

//registers needed for instantiation of cnn engine
reg cnn_start, pool_start, fc_start;
reg cnn_done, pool_done, fc_done;

//output wires needed for inter-layer connection
reg signed [31:0] conv_output [0:35];
reg signed [31:0] pool_output [0:8];
reg signed [31:0] fc_output;

//FSM states
localparam IDLE = 3'b000,
           CNN_START = 3'b001,
           CNN_WAIT = 3'b010,
           POOL_START = 3'b011,
           POOL_WAIT = 3'b100,
           FC_START = 3'b101,
           FC_WAIT = 3'b110,
           DONE = 3'b111;

reg [2:0] state;
assign value = fc_output;

//layer 1 : convolutional layer
cnn_engine conv_layer(
    .clk(clk),
    .rst(rst),
    .start(cnn_start),
    .input_ram(input_img),
    .done(cnn_done),
    .output_ram(conv_output)
);

//layer 2 : pool layer
pool_layer pool_layer(
    .clk(clk),
    .rst(rst),
    .start(pool_start),
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
always @ (posedge clk) begin
  if (rst) begin
    cnn_start = 0;
    pool_start = 0;
    fc_start = 0;
    state = IDLE;
  end else begin
    cnn_start <= 1;
    case(state) 
      IDLE: begin
        if(enable) begin
          $display("Starting CNN processing at time %t", $time);
          state <= CNN_START;
          //cnn_start <= 1;
        end else begin
          done <= 0; //if not enabled, stay in IDLE
        end
      end
      CNN_START: begin
        cnn_start <= 0;
        state <= CNN_WAIT;
        $display("value of cnn_done signal at time %t is %b", $time, cnn_done);
      end
      CNN_WAIT: begin
        if(cnn_done == 1) begin
          pool_start <= 1;
          state <= POOL_START;
        end
      end
      POOL_START: begin
        pool_start <= 0;
        state <= POOL_WAIT;
      end
      POOL_WAIT: begin
        if(pool_done == 1) begin
          fc_start <= 1;
          state <= FC_START;
        end
      end
      FC_START: begin
        fc_start <= 0;
        state <= FC_WAIT;
      end
      FC_WAIT: begin
        if(fc_done == 1) begin
          done <= 1;
          state <= DONE;
        end
      end
      DONE: begin
        done <= 0;
      end
    endcase
  end
end
endmodule