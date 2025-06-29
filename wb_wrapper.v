//===========================
// Wishbone Wrapper for dual_ram
//===========================

module dual_ram_wb #(parameter addr_width = 32, data_width = 32)(
    input clk,
    input rst,

    // Wishbone interface
    input           wb_cyc_i,
    input           wb_stb_i,
    input           wb_we_i,
    input [addr_width-1:0] wb_adr_i,
    input [data_width-1:0] wb_dat_i,
    output reg [data_width-1:0] wb_dat_o,
    output reg      wb_ack_o,

    // Dual port RAM connections (cnn is port b)
    input           cnn_we,
    input [addr_width-1:0] cnn_addr,
    input [data_width-1:0] cnn_data,
    output [data_width-1:0] cnn_q
);

    wire ram_we_a = wb_cyc_i & wb_stb_i & wb_we_i;
    wire ram_en_a = wb_cyc_i & wb_stb_i;

    wire [data_width-1:0] ram_q_a;

    dual_ram #(addr_width, data_width) ram_inst (
        .clk(clk),
        .we_a(ram_we_a),
        .addr_a(wb_adr_i),
        .data_a(wb_dat_i),
        .mem_a(ram_q_a),

        .we_b(cnn_we),
        .addr_b(cnn_addr),
        .data_b(cnn_data),
        .mem_b(cnn_q)
    );

    always @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 0;
            wb_dat_o <= 0;
        end else if (ram_en_a) begin
            wb_ack_o <= 1;
            wb_dat_o <= ram_q_a;
        end else begin
            wb_ack_o <= 0;
        end
    end

endmodule

//===========================
// Wishbone Wrapper for GPIO Module
//===========================

module gpio_wb (
    input clk,
    input rst,

    // Wishbone interface
    input           wb_cyc_i,
    input           wb_stb_i,
    input           wb_we_i,
    input [31:0]    wb_adr_i,
    input [31:0]    wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg      wb_ack_o,

    // GPIO outputs
    output reg led1,
    output reg led2,
    output reg led3,
    output reg led4,
    output reg led_done
);

    always @(posedge clk) begin
        if (rst) begin
            led1 <= 0; led2 <= 0; led3 <= 0; led4 <= 0; led_done <= 0;
            wb_ack_o <= 0;
        end else if (wb_cyc_i && wb_stb_i) begin
            wb_ack_o <= 1;
            if (wb_we_i) begin
                // Write operation
                {led_done, led4, led3, led2, led1} <= wb_dat_i[4:0];
            end else begin
                // Read operation
                wb_dat_o <= {27'd0, led_done, led4, led3, led2, led1};
            end
        end else begin
            wb_ack_o <= 0;
        end
    end

endmodule

//===========================
// Note: The UART Wishbone wrapper will be used from ZipCPU's "wbuart32" repo
//===========================
// Instantiate wbuart and map the Wishbone ports in your top-level interconnect.
// No wrapper needed unless you modify the UART itself.
