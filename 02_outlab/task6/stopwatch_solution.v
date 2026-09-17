module stopwatch (
    input  wire clk,
    input  wire rst,
    input  wire start_stop,   // one clock-cycle pulse per "button press"
    output reg [3:0] sec_ones,
    output reg [3:0] sec_tens,
    output reg [3:0] min_ones,
    output reg [3:0] min_tens,
    output wire tick_out
);
    wire tick;
    reg  running;

    tick_gen #(.LIMIT(4)) tg (
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );

    assign tick_out = tick;

    always @(posedge clk) begin
        if (rst)
            running <= 1'b0;
        else if (start_stop)
            running <= ~running;
    end

    // Combinational: does each digit roll over this tick, and does it
    // carry into the next digit?
    wire sec_ones_roll = (sec_ones == 4'd9);
    wire sec_tens_roll = (sec_tens == 4'd5);   // seconds only go 0-59
    wire min_ones_roll = (min_ones == 4'd9);
    wire min_tens_roll = (min_tens == 4'd5);   // minutes wrap the same way

    wire sec_ones_carry = sec_ones_roll;
    wire sec_tens_carry = sec_ones_carry & sec_tens_roll;
    wire min_ones_carry = sec_tens_carry & min_ones_roll;
    wire min_tens_carry = min_ones_carry & min_tens_roll;

    always @(posedge clk) begin
        if (rst) begin
            sec_ones <= 4'd0;
            sec_tens <= 4'd0;
            min_ones <= 4'd0;
            min_tens <= 4'd0;
        end else if (running && tick) begin
            sec_ones <= sec_ones_roll ? 4'd0 : sec_ones + 4'd1;
            sec_tens <= sec_ones_carry ? (sec_tens_roll ? 4'd0 : sec_tens + 4'd1) : sec_tens;
            min_ones <= sec_tens_carry ? (min_ones_roll ? 4'd0 : min_ones + 4'd1) : min_ones;
            min_tens <= min_ones_carry ? (min_tens_roll ? 4'd0 : min_tens + 4'd1) : min_tens;
        end
    end
endmodule
