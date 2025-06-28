module bus_decoder(
    input [9:0] data_addr,
    input re,
    input we,
    output sel_ram, sel_uart, sel_gpio,
    output re_ram, re_uart, re_gpio,
    output we_ram, we_uart, we_gpio
);

assign sel_ram = (addr[31:28] == 4'h1);
assign sel_uart = (addr[31:28] == 4'h2);
assign sel_gpio = (addr[31:28] == 4'h3);

assign we_ram = sel_ram & we;
assign we_uart = sel_uart & we;
assign we_gpio = sel_gpio & we;

assign re_ram = sel_ram & re;
assign re_uart = sel_uart & re;
assign re_gpio = sel_gpio & re;

endmodule