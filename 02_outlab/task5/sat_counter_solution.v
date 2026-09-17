module sat_counter (
    input wire clk,
    input wire rst,
    input wire up,
    input wire down,
    output reg [3:0] count
);
    wire [3:0] next_count;

    assign next_count =
        (up && !down && count != 4'd15) ? count + 4'd1 :
        (down && !up && count != 4'd0)  ? count - 4'd1 :
                                            count;

    always @(posedge clk) begin
        if (rst)
            count <= 4'd0;
        else
            count <= next_count;
    end
endmodule
