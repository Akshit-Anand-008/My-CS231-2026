module loadable_reg (
    input wire clk,
    input wire rst,
    input wire load,
    input wire d,
    output reg q
);
    wire next_q;

    mux_behavioral sel_mux (
        .a(q),
        .b(d),
        .sel(load),
        .y(next_q)
    );

    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= next_q;
    end
endmodule
