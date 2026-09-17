// Corrected versions of reg_bug1..reg_bug4 from buggy_regs.v.
// Each module should behave like Task 3's loadable_reg: synchronous reset
// takes priority over load, and q holds its value when load is low.

module reg_bug1_fixed (
    input wire clk,
    input wire rst,
    input wire load,
    input wire d,
    output reg q
);
    reg next_q;

    // Fix: sensitivity list must include every signal read inside the block,
    // not just load, or the block behaves like a latch in simulation instead
    // of true combinational logic.
    always @(*) begin
        if (load)
            next_q = d;
        else
            next_q = q;
    end

    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= next_q;
    end
endmodule

module reg_bug2_fixed (
    input wire clk,
    input wire rst,
    input wire load,
    input wire d,
    output reg q
);
    reg next_q;

    // Fix: every branch must assign next_q, or an unintended latch is
    // inferred to hold next_q's value when load is low.
    always @(*) begin
        if (load)
            next_q = d;
        else
            next_q = q;
    end

    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= next_q;
    end
endmodule

module reg_bug3_fixed (
    input wire clk,
    input wire rst,
    input wire load,
    input wire d,
    output reg q
);
    wire next_q;

    assign next_q = load ? d : q;

    // Fix: use non-blocking assignments inside the clocked block so all
    // reads use pre-edge values, avoiding order-dependent races when this
    // register is chained with others.
    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= next_q;
    end
endmodule

module reg_bug4_fixed (
    input wire clk,
    input wire rst,
    input wire load,
    input wire d,
    output reg q
);
    // Fix: a reg should only be driven from a single always block. Merge
    // the two blocks and use if/else priority instead of relying on
    // simulation/synthesis order between two blocks triggered by the same
    // edge.
    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else if (load)
            q <= d;
    end
endmodule
