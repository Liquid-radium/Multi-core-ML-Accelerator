module gpio_module(
    input clk,
    input rst,
    input [1:0] ctrl,
    output reg led1,
    output reg led2,
    output reg led3,
    output reg led4,
    output reg led_done
);

localparam IDLE = 0,
           START_CORES = 1,
           WAIT_FOR_DONE = 2,
           DONE_STATE = 3;

always @ (posedge clk) begin
  if (rst) begin
    led1 <= 0;
    led2 <= 0;
    led3 <= 0;
    led4 <= 0;
  end else begin
    case(ctrl) 
        IDLE: begin
          led1 <= 1;
          ctrl <= START_CORES;
        end
        START_CORES: begin
          led1 <= 0;
          led2 <= 1;
          ctrl <= WAIT_FOR_DONE;
        end
        WAIT_FOR_DONE: begin
          led2 <= 0;
          led3 <= 1;
          ctrl <= DONE_STATE;
        end
        DONE_STATE: begin
          led3 <= 0;
          led4 <= 1;
          led_done <= 1;
        end
    endcase
  end
end
endmodule