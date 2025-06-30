`include "wb_wrapper.v"

module wb_interconnect(
    input clk,
    input rst,

    input i_wb_cyc,
    input i_wb_stb,
    input [3:0] i_wb_sel,
    input [31:0] i_wb_addr,
    input [31:0] i_wb_data,
    input re,
    input we,
    output [31:0] o_wb_data,
    output o_wb_ack,
    output o_wb_stall,

    input uart_rx,
    output uart_tx,

    inout [3:0] gpio_pins
);

parameter addr_width = 32;
parameter data_width = 8;

wire sel_ram, sel_uart, sel_gpio, sel_cnn;

bus_decoder decoder(
    .data_addr(i_wb_addr),
    .re(re),
    .we(we),
    .sel_ram(sel_ram),
    .sel_cnn(sel_cnn),
    .sel_gpio(sel_gpio),
    .sel_uart(sel_uart),
    .re_cnn(re & sel_cnn),
    .re_gpio(re & re_gpio),
    .re_ram(re & re_ram),
    .re_uart(re & re_uart),
    .we_cnn(we & we_cnn),
    .we_gpio(we & we_gpio),
    .we_ram(we & we_ram),
    .we_uart(we & we_uart)
);

wire [31:0] ram_data, uart_data, gpio_data, cnn_data;
wire ram_ack, cnn_ack, gpio_ack, uart_ack;

dual_ram_wb ram_inst (
        .clk(clk), .rst(rst),
        .i_wb_cyc(i_wb_cyc & sel_ram),
        .i_wb_stb(i_wb_stb & sel_ram),
        .i_wb_we(i_wb_we),
        .i_wb_sel(i_wb_sel),
        .i_wb_addr(i_wb_addr),
        .i_wb_data(i_wb_data),
        .o_wb_data(ram_data),
        .o_wb_ack(ram_ack)
);

// UART
wbuart uart_inst (
        .i_clk(clk),
        .i_wb_cyc(i_wb_cyc & sel_uart),
        .i_wb_stb(i_wb_stb & sel_uart),
        .i_wb_we(i_wb_we),
        .i_wb_addr(i_wb_addr[4:0]), // UART uses local address
        .i_wb_data(i_wb_data),
        .o_wb_data(uart_data),
        .o_wb_ack(uart_ack),
        .o_wb_stall(uart_stall),
        .i_rx(uart_rx),
        .o_tx(uart_tx),
        .o_int() // optional
); 

// GPIO
gpio_wb gpio_inst (
        .clk(clk), .rst(rst),
        .i_wb_cyc(i_wb_cyc & sel_gpio),
        .i_wb_stb(i_wb_stb & sel_gpio),
        .i_wb_we(i_wb_we),
        .i_wb_sel(i_wb_sel),
        .i_wb_addr(i_wb_addr[4:0]),
        .i_wb_data(i_wb_data),
        .o_wb_data(gpio_data),
        .o_wb_ack(gpio_ack),
        .o_wb_stall(gpio_stall),
        .io_pins(gpio_pins)    
);

// CNN Core
cnn_top cnn_inst (
        .clk(clk), .rst(rst),
        .i_wb_cyc(i_wb_cyc & sel_cnn),
        .i_wb_stb(i_wb_stb & sel_cnn),
        .i_wb_we(i_wb_we),
        .i_wb_sel(i_wb_sel),
        .i_wb_addr(i_wb_addr),
        .i_wb_data(i_wb_data),
        .o_wb_data(cnn_data),
        .o_wb_ack(cnn_ack),
        .o_wb_stall(cnn_stall)
);    

// output mux
assign o_wb_data = sel_ram ? ram_data :
                   sel_uart ? uart_data :
                   sel_gpio ? gpio_data :
                   sel_cnn ? cnn_data : 32'hDEAD_BEEF;

assign o_wb_ack = sel_ram ? ram_ack :
                  sel_uart ? uart_ack :
                  sel_gpio ? gpio_ack :
                  sel_cnn ? cnn_ack : 32'hDEAD_BEEF;

endmodule      