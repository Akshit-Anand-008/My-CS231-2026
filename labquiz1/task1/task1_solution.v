module mux2 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
    assign y = sel ? b : a;
endmodule


module mux4 (
    input  wire [3:0] d,
    input  wire [1:0] sel,
    output wire       y
);
    wire lo, hi;
    mux2 m_lo  (.a(d[0]), .b(d[1]), .sel(sel[0]), .y(lo));
    mux2 m_hi  (.a(d[2]), .b(d[3]), .sel(sel[0]), .y(hi));
    mux2 m_out (.a(lo),   .b(hi),   .sel(sel[1]), .y(y));
endmodule


module mux4_bus (
    input  wire [7:0] d0,
    input  wire [7:0] d1,
    input  wire [7:0] d2,
    input  wire [7:0] d3,
    input  wire [1:0] sel,
    output wire [7:0] y
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bitslice
            mux4 m (.d({d3[i], d2[i], d1[i], d0[i]}), .sel(sel), .y(y[i]));
        end
    endgenerate
endmodule


module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] op,
    output wire [7:0] y
);
    wire [7:0] r_add = a + b;
    wire [7:0] r_sub = a - b;
    wire [7:0] r_and = a & b;
    wire [7:0] r_or  = a | b;
    mux4_bus sel_out (.d0(r_add), .d1(r_sub), .d2(r_and), .d3(r_or), .sel(op), .y(y));
endmodule
