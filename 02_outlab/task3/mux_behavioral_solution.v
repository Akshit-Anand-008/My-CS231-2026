module mux_behavioral (
    input wire a,
    input wire b,
    input wire sel,
    output reg y
);
    always @(*) begin
        if (sel)
            y = b;
        else
            y = a;
    end
endmodule
