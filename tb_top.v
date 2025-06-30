`timescale 1ns/1ps

module tb_top;

//dut signals 
reg clk;
reg rst;
reg i_wb_cyc;
reg i_wb_stb;
reg [3:0] i_wb_sel;
reg [31:0] i_wb_addr;
reg [31:0] i_wb_data;
reg i_wb_we;
reg i_wb_re;
wire [31:0] o_wb_data;
wire o_wb_ack;
wire o_wb_stall;
reg uart_rx;
wire uart_tx;
wire [3:0] gpio_pins;

//instantiating the module
wb_interconnect dut(
    .clk(clk),
    .rst(rst),
    .i_wb_cyc(i_wb_cyc),
    .i_wb_stb(i_wb_stb),
    .i_wb_sel(i_wb_sel),
    .i_wb_addr(i_wb_addr),
    .i_wb_data(i_wb_data),
    .re(i_wb_re),
    .we(i_wb_we),
    .o_wb_data(o_wb_data),
    .o_wb_ack(o_wb_ack),
    .o_wb_stall(o_wb_stall),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .gpio_pins(gpio_pins)
);

assign uart_rx = uart_tx;
integer i;

initial clk = 0;
always #5 clk = ~clk;

//task: wishbone write
task wb_write(input [31:0] addr, input [31:0] data);
begin
  @(posedge clk);
        i_wb_addr <= addr;
        i_wb_data <= data;
        i_wb_sel  <= 4'b1111;
        i_wb_cyc  <= 1;
        i_wb_stb  <= 1;
        i_wb_we   <= 1;
        wait (o_wb_ack);
        @(posedge clk);
        i_wb_cyc  <= 0;
        i_wb_stb  <= 0;
        i_wb_we   <= 0;
end
endtask

//task: wishbone read
task wb_read(input [31:0] addr);
        begin
            @(posedge clk);
            i_wb_addr <= addr;
            i_wb_sel  <= 4'b1111;
            i_wb_cyc  <= 1;
            i_wb_stb  <= 1;
            i_wb_we   <= 0;
            wait (o_wb_ack);
            @(posedge clk);
            $display("Read from %h: %h", addr, o_wb_data);
            i_wb_cyc  <= 0;
            i_wb_stb  <= 0;
        end
endtask

initial begin
  rst = 1;
  i_wb_cyc = 0;
  i_wb_stb = 0;
  i_wb_we = 0;
  i_wb_sel = 4'b1111;
  i_wb_addr = 0;
  i_wb_data = 0;
  #50;

  rst = 0;
  #50;

  for(i = 0; i <64; i = i +1)begin
    wb_write(32'h0000_0000 + i, i);
  end
  wb_write(32'h4000_0000, 32'h1);
  wait(dut.cnn_inst.cnn_ack);
  wb_read(32'h4000_0004);
  #100;
  $stop;
end
endmodule