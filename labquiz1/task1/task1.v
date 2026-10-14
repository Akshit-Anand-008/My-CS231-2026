// Question 1: fill in the four modules below, all in this file.
// If you only attempt some parts, leave the rest as they are --- the
// testbench will simply report the unfinished modules as failing.

module mux2 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
    // TODO
endmodule


module mux4 (
    input  wire [3:0] d,
    input  wire [1:0] sel,
    output wire       y
);
    // TODO
endmodule


module mux4_bus (
    input  wire [7:0] d0,
    input  wire [7:0] d1,
    input  wire [7:0] d2,
    input  wire [7:0] d3,
    input  wire [1:0] sel,
    output wire [7:0] y
);
    // TODO
endmodule


module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] op,
    output wire [7:0] y
);
    // TODO
endmodule
