module relu_unit(
    input [31:0] mac_acc,
    output [31:0] relu_acc
);

assign relu_acc = (mac_acc > 0) ? mac_acc : 0;
endmodule