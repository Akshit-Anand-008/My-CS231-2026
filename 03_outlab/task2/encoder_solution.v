module encoder (
    input  [3:0] data,
    input        enable,
    output [4:0] encoded
);

    wire d3 = data[3];
    wire d2 = data[2];
    wire d1 = data[1];
    wire d0 = data[0];

    wire e4 = d3 | (~d2 & (d1 | ~d0));
    wire e3 = d2 | (~d3 & ~d1);
    wire e2 = d1 | (~d3 & ~d2 & ~d1 & ~d0);
    wire e1 = (d3 ^ d2) | (~d1 & ~d0) | (d3 & ~d1);
    wire e0 = d0;

    assign encoded = enable ? {e4, e3, e2, e1, e0} : 5'b00000;

endmodule