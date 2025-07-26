module gpio_module(
    input clk,
    input rst,
    output reg led1,
    output reg led2,
    output reg led3,
    output reg led4,
    output reg led_done
);

reg [1:0] ctrl;

localparam IDLE = 2'b00,
           START_CORES = 2'b01,
           WAIT_FOR_DONE = 2'b10,
           DONE_STATE = 2'b11;

always @ (posedge clk) begin
  if (rst) begin
    led1 = 0;
    led2 = 0;
    led3 = 0;
    led4 = 0;
  end else begin
    case(ctrl) 
        IDLE: begin
          led1 <= 1;
          ctrl <= START_CORES;
        end
        START_CORES: begin
          //led1 <= 0;
          led2 <= 1;
          ctrl <= WAIT_FOR_DONE;
        end
        WAIT_FOR_DONE: begin
          //led2 <= 0;
          led3 <= 1;
          ctrl <= DONE_STATE;
        end
        DONE_STATE: begin
          //led3 <= 0;
          led4 <= 1;
          led_done <= 1;
        end
    endcase
  end
end
endmodule