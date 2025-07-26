`timescale 1ns/1ps

module tb_top;

// Wishbone DUT signals
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

// UART and GPIO
reg uart_rx;
wire uart_tx;
wire [3:0] gpio_pins;

// Instantiate DUT (your Wishbone interconnect + CNN)
wb_interconnect dut (
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

assign uart_rx = uart_tx;  // Loopback for UART if needed

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

// 8x8 grayscale image = 64 pixels
reg [7:0] input_image [0:63];  // 8-bit grayscale pixels

integer i;

// Wishbone Write Task
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

// Wishbone Read Task
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

// Initialization and Stimulus
initial begin
    // Reset and defaults
    rst = 1;
    i_wb_cyc = 0;
    i_wb_stb = 0;
    i_wb_we  = 0;
    i_wb_sel = 4'b1111;
    i_wb_addr = 0;
    i_wb_data = 0;

    #50;
    rst = 0;
    #50;

    // Initialize image pixels with values 0 to 63
    for (i = 0; i < 64; i = i + 1)begin
        input_image[i] = i;  // Example: simple pattern
    end
    $display("Input Image:");

    // Pack 4 pixels per 32-bit word and write to memory
    for (i = 0; i < 64; i = i + 4) begin
        wb_write(32'h0000_0000 + (i >> 2)*4,
            {input_image[i+3], input_image[i+2], input_image[i+1], input_image[i]});
        
    end
    $display("Image written to memory.");

    // Trigger CNN operation
    wb_write(32'h4000_0000, 32'h1);  // Control register: start
    $display("CNN processing started.");

    // Wait for CNN to complete (wait for o_wb_ack or monitor status)
    wait(dut.cnn_inst.o_wb_ack);
    $display("CNN processing completed.");

    // Read output (assuming results start at 0x4000_0004)
    $display("\n---- Output Feature Map ----");
    for (i = 0; i < 16; i = i + 1) begin  // Assuming 4x4 output for 2x2 avg pooling
        wb_read(32'h4000_0004 + i*4);
    end
    $display("Output feature map read from memory.");

    #100;
    $stop;
end

endmodule
