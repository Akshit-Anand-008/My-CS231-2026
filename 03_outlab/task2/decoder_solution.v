module decoder (
    input  [4:0] encoded,
    input        enable,
    output [3:0] data,
    output       valid
);

    wire v = encoded[4];
    wire w = encoded[3];
    wire x = encoded[2];
    wire y = encoded[1];
    wire z = encoded[0];

    wire p1 = (v | w) & ~x & y;
    wire p2 = v & x & ~y;
    wire p3 = (v ^ w) & x & y;
    wire r1 = ~v & w & ~x & ~y & z;
    wire r2 = v & w & x & y & ~z;
    
    wire is_valid = p1 | p2 | p3 | r1 | r2;
    assign valid = enable & is_valid;

    wire d0 = z;
    wire d1 = x & ~(v & w & y);
    wire d2 = w & ( (v ^ y) | (v & ~x) );
    wire d3 = v & ( (~x & y) | (w ^ y) );

    // Mask data when invalid or disabled
    assign data = valid ? {d3, d2, d1, d0} : 4'b0000;

endmodule