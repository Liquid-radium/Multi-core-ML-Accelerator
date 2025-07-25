module relu_unit(
    input [31:0] fc_op,
    output [31:0] relu_acc
);

assign relu_acc = (fc_op > 0) ? fc_op : 0;
endmodule