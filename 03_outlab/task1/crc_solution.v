// ================================================================
// Part A: CRC-8 (fixed width=8, polynomial=0xD5)
// ================================================================

// Module 1: crc8_update (combinational)
// Given the current CRC register and one incoming bit,
// compute the next CRC value. One iteration of the CRC loop.
module crc8_update (
    input  [7:0] crc_in,
    input        data_bit,
    output [7:0] crc_out
);
    wire feedback;
    assign feedback = crc_in[7] ^ data_bit;
    assign crc_out  = feedback ? ({crc_in[6:0], 1'b0} ^ 8'hD5)
                               :  {crc_in[6:0], 1'b0};
endmodule


// Module 2: crc8_serial (sequential)
// Accepts serial bits one per clock via data_bit.
// data_valid indicates that data_bit should be consumed.
// data_last indicates that data_bit is the final bit.
// crc_valid pulses when the CRC has been updated with the final bit.
module crc8_serial (
    input        clk,
    input        rst,
    input        data_bit,
    input        data_valid,
    input        data_last,
    output [7:0] crc,
    output       crc_valid
);
    reg  [7:0] crc_reg;
    reg        crc_valid_reg;
    wire [7:0] crc_next;

    crc8_update u_update (
        .crc_in   (crc_reg),
        .data_bit (data_bit),
        .crc_out  (crc_next)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg       <= 8'hFF;
            crc_valid_reg <= 1'b0;
        end else begin
            crc_valid_reg <= 1'b0;

            if (data_valid) begin
                crc_reg <= crc_next;

                if (data_last)
                    crc_valid_reg <= 1'b1;
            end
        end
    end

    assign crc       = crc_reg;
    assign crc_valid = crc_valid_reg;

endmodule


// ================================================================
// Part B: Parametric CRC (general WIDTH and POLY)
// ================================================================

// Module 1: crc_update (combinational, parametric)
// Same logic as crc8_update but for any WIDTH and POLY.
module crc_update #(
    parameter             WIDTH = 8,
    parameter [WIDTH-1:0] POLY = 8'hD5
) (
    input  [WIDTH-1:0] crc_in,
    input              data_bit,
    output [WIDTH-1:0] crc_out
);
    wire feedback;
    assign feedback = crc_in[WIDTH-1] ^ data_bit;
    assign crc_out  = feedback ? ({crc_in[WIDTH-2:0], 1'b0} ^ POLY)
                               :  {crc_in[WIDTH-2:0], 1'b0};
endmodule


// Module 2: crc_serial (sequential, parametric)
// Same as crc8_serial but instantiates parametric crc_update.
module crc_serial #(
    parameter             WIDTH = 8,
    parameter [WIDTH-1:0] POLY = 8'hD5,
    parameter [WIDTH-1:0] INIT = {WIDTH{1'b1}}
) (
    input                  clk,
    input                  rst,
    input                  data_bit,
    input                  data_valid,
    input                  data_last,
    output [WIDTH-1:0]     crc,
    output                 crc_valid
);
    reg  [WIDTH-1:0] crc_reg;
    reg              crc_valid_reg;
    wire [WIDTH-1:0] crc_next;

    crc_update #(.WIDTH(WIDTH), .POLY(POLY)) u_update (
        .crc_in   (crc_reg),
        .data_bit (data_bit),
        .crc_out  (crc_next)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg       <= INIT;
            crc_valid_reg <= 1'b0;
        end else begin
            crc_valid_reg <= 1'b0;

            if (data_valid) begin
                crc_reg <= crc_next;

                if (data_last)
                    crc_valid_reg <= 1'b1;
            end
        end
    end

    assign crc       = crc_reg;
    assign crc_valid = crc_valid_reg;

endmodule

// ================================================================
// Part C: Parallel CRC (DATA_WIDTH bits per clock)
// ================================================================

// Module 1: crc_parallel (combinational)
// Processes DATA_WIDTH input bits in one combinational pass.
// The bits are processed from MSB to LSB.
module crc_parallel #(
    parameter                    WIDTH      = 8,
    parameter [WIDTH-1:0]        POLY       = 8'hD5,
    parameter                    DATA_WIDTH = 8
) (
    input  [WIDTH-1:0] crc_in,
    input  [DATA_WIDTH-1:0] data,
    output [WIDTH-1:0] crc_out
);
    wire [WIDTH-1:0] crc_stage [0:DATA_WIDTH];

    assign crc_stage[0] = crc_in;

    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_crc
            crc_update #(
                .WIDTH(WIDTH),
                .POLY(POLY)
            ) u_update (
                .crc_in   (crc_stage[i]),
                .data_bit (data[DATA_WIDTH-1-i]),
                .crc_out  (crc_stage[i+1])
            );
        end
    endgenerate

    assign crc_out = crc_stage[DATA_WIDTH];

endmodule


// Module 2: crc_parallel_serial (sequential)
// Accepts DATA_WIDTH bits per clock and updates the CRC once per
// valid input word. data_last marks the final word.
module crc_parallel_serial #(
    parameter                    WIDTH      = 8,
    parameter [WIDTH-1:0]        POLY       = 8'hD5,
    parameter [WIDTH-1:0]        INIT       = {WIDTH{1'b1}},
    parameter                    DATA_WIDTH = 8
) (
    input                    clk,
    input                    rst,
    input  [DATA_WIDTH-1:0] data,
    input                    data_valid,
    input                    data_last,
    output [WIDTH-1:0]        crc,
    output                   crc_valid
);
    reg [WIDTH-1:0] crc_reg;
    reg             crc_valid_reg;
    wire [WIDTH-1:0] crc_next;

    crc_parallel #(
        .WIDTH(WIDTH),
        .POLY(POLY),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_parallel (
        .crc_in  (crc_reg),
        .data     (data),
        .crc_out  (crc_next)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg       <= INIT;
            crc_valid_reg <= 1'b0;
        end else begin
            crc_valid_reg <= 1'b0;

            if (data_valid) begin
                crc_reg <= crc_next;

                if (data_last)
                    crc_valid_reg <= 1'b1;
            end
        end
    end

    assign crc       = crc_reg;
    assign crc_valid = crc_valid_reg;

endmodule