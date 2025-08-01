module bus_decoder(
    input [31:0] data_addr,
    input re,
    input we,
    output sel_ram, sel_uart, sel_gpio, sel_cnn,
    output re_ram, re_uart, re_gpio, re_cnn,
    output we_ram, we_uart, we_gpio, we_cnn
);

assign sel_ram = (data_addr[31:28] == 4'h1);
assign sel_uart = (data_addr[31:28] == 4'h2);
assign sel_gpio = (data_addr[31:28] == 4'h3);
assign sel_cnn = (data_addr[31:28] == 4'h4);

assign we_ram = sel_ram & we;
assign we_uart = sel_uart & we;
assign we_gpio = sel_gpio & we;
assign we_cnn = sel_cnn & we;

assign re_ram = sel_ram & re;
assign re_uart = sel_uart & re;
assign re_gpio = sel_gpio & re;
assign re_cnn = sel_cnn & re;

endmodule