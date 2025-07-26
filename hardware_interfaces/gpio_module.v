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
    $display("GPIO module initialized at time %t", $time);
    led1 <= 0;
    case(ctrl) 
        IDLE: begin
          led1 <= 1;
          ctrl <= START_CORES;
          $display("GPIO module is in IDLE state at time %t", $time);
          $display("LED1 is ON at time %t", $time);
        end
        START_CORES: begin
          //led1 <= 0;
          led2 <= 1;
          ctrl <= WAIT_FOR_DONE;
          $display("Starting cores at time %t", $time);
          $display("LED2 is ON at time %t", $time);
        end
        WAIT_FOR_DONE: begin
          //led2 <= 0;
          led3 <= 1;
          ctrl <= DONE_STATE;
          $display("Waiting for cores to finish at time %t", $time);
          $display("LED3 is ON at time %t", $time);
        end
        DONE_STATE: begin
          //led3 <= 0;
          led4 <= 1;
          led_done <= 1;
          ctrl <= IDLE;
          $display("All cores done at time %t", $time);
          $display("LED4 is ON at time %t", $time);
        end
    endcase
  end
end
endmodule