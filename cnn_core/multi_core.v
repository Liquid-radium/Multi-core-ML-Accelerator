module multi_core #(
    parameter N = 4,
    parameter img_size = 64,
    parameter output_size = 32
)(
    input clk,
    input rst, 
    input [31:0] input_images [0:N-1][0:img_size-1],
    output [output_size-1:0] predictions[0 : N-1],
    output reg all_done
);

wire done [0: N-1];
reg begin_core [0 : N-1];
genvar i;
integer j;
integer all_done_check;

generate
for(i = 0; i < N; i=i+1)begin
  cnn_top core(
    .clk(clk),
    .rst(rst),
    .enable(begin_core[i]),
    .input_img(input_images[i]),
    .value(predictions[i]),
    .done(done[i])
  );
end
endgenerate

reg [2:0] state;
localparam IDLE = 0,
           START_CORES = 1,
           WAIT_FOR_DONE = 2,
           DONE_STATE = 3;

always @ (posedge clk) begin
  if (rst) begin
    state <= IDLE;
    for(j=0; j<N; j=j+1)begin
      begin_core[j] <= 0;
    end
  end else begin
    case(state)
        IDLE: begin
          for(j = 0; j<N; j=j+1)begin
            begin_core[j] = 1;
          end
          state <= START_CORES;
        end
        START_CORES: begin
          for(j=0; j<N; j=j+1)begin
            begin_core[j] <= 0;
          end
          state <= WAIT_FOR_DONE;
        end
        WAIT_FOR_DONE: begin
          for(j=0; j<N; j=j+1)begin
            if(!done[j])begin
              all_done_check = 0;
            end
          end
          if(all_done_check)begin
            all_done <= 1;
            state <= DONE_STATE;
          end
        end
        DONE_STATE: begin
          //holds done signal
        end
    endcase
  end
end
endmodule