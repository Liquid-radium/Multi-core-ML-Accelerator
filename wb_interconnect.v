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
parameter data_width = 32;

wire sel_ram, sel_uart, sel_gpio, sel_cnn;
wire re_cnn, re_gpio, re_ram, re_uart;
wire we_cnn, we_gpio, we_ram, we_uart;

bus_decoder decoder(
    .data_addr(i_wb_addr),
    .re(re),
    .we(we),
    .sel_ram(sel_ram),
    .sel_cnn(sel_cnn),
    .sel_gpio(sel_gpio),
    .sel_uart(sel_uart),
    .re_cnn(re_cnn),
    .re_gpio(re_gpio),
    .re_ram(re_ram),
    .re_uart(re_uart),
    .we_cnn(we_cnn),
    .we_gpio(we_gpio),
    .we_ram(we_ram),
    .we_uart(we_uart)
);

wire [31:0] ram_data, uart_data, gpio_data, cnn_data;
wire [31:0] cnn_addr, ram_addr, gpio_addr, uart_addr;
wire ram_ack, cnn_ack, gpio_ack, uart_ack;

dual_ram_wb ram_inst (
        .clk(clk), .rst(rst),
        .wb_cyc_i(i_wb_cyc & sel_ram),
        .wb_stb_i(i_wb_stb & sel_ram),
        .wb_we_i(i_wb_we),
        .wb_sel_i(i_wb_sel),
        .wb_adr_i(i_wb_addr),
        .wb_dat_i(i_wb_data),
        .wb_dat_o(ram_data),
        .wb_ack_o(ram_ack),
        .cnn_we(we_cnn),
        .cnn_data(cnn_data),
        .cnn_addr(cnn_addr),
        .cnn_q(cnn_data)

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
        .i_uart_rx(uart_rx),
        .o_uart_tx(uart_tx)
); 

// GPIO
gpio_wb gpio_inst (
        .clk(clk), .rst(rst),
        .wb_cyc_i(i_wb_cyc & sel_gpio),
        .wb_stb_i(i_wb_stb & sel_gpio),
        .wb_we_i(i_wb_we),
        .wb_sel_i(i_wb_sel),
        .wb_adr_i(i_wb_addr[4:0]),
        .wb_dat_i(wb_dat),
        .wb_dat_o(gpio_data),
        .wb_ack_o(gpio_ack),
        .led1(gpio_pins[0]),
        .led2(gpio_pins[1]),
        .led3(gpio_pins[2]),
        .led4(gpio_pins[3])    
);

// CNN Core
multi_core_wb cnn_inst (
        .clk(clk), .rst(rst),
        .i_wb_cyc(i_wb_cyc),
        .i_wb_stb(i_wb_stb),
        .i_wb_we(i_wb_we),
        .i_wb_sel(i_wb_sel),
        .i_wb_addr(i_wb_addr),
        .i_wb_data(i_wb_data),
        .o_wb_data(o_wb_data),
        .o_wb_ack(o_wb_ack),
        .o_wb_stall(o_wb_stall)
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