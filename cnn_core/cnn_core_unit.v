module cnn_top(
    input clk,
    input rst,
    input enable,
    input [31:0] input_img [0:63],
    output reg [31:0] value,
    output reg done
);

// FSM state register
    logic [2:0] state;

    // Control signals
    logic cnn_start, cnn_done;
    logic pool_start, pool_done;
    logic fc_start, fc_done;

    // Inter-layer storage
    logic signed [31:0] conv_output [0:35]; // Output of 6x6 conv
    logic signed [31:0] pool_output [0:8];  // Output of 3x3 pool
    logic signed [31:0] fc_output;          // Final output before ReLU
    logic signed [31:0] relu_acc;           // Final output after ReLU

    assign value = relu_acc; // Final system output

//FSM states
localparam IDLE = 3'b000,
           CNN_START = 3'b001,
           CNN_WAIT = 3'b010,
           POOL_START = 3'b011,
           POOL_WAIT = 3'b100,
           FC_START = 3'b101,
           FC_WAIT = 3'b110,
           DONE = 3'b111;

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

relu_unit relu(
    .fc_op(fc_output),
    .relu_acc(value)
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
          //$display("Starting CNN processing at time %t", $time);
          state <= CNN_START;
          //cnn_start <= 1;
        end else begin
          done <= 0; //if not enabled, stay in IDLE
        end
      end
      CNN_START: begin
        cnn_start <= 0;
        state <= CNN_WAIT;
        //$display("value of cnn_done signal at time %t is %b", $time, cnn_done);
      end
      CNN_WAIT: begin
      //$display("Waiting for CNN layer to finish at time %t", $time);
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