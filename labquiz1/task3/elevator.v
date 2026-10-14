// Question 3. Parts A and B are required; part C is optional. Fill in both
// modules below.

module floor_datapath (
    input      [2:0] current_floor,
    input            move_up,
    input            move_down,
    output     [2:0] next_floor
);
    // TODO (Part A)
endmodule


module elevator (
    input            clk,
    input            rst,
    input      [2:0] internal_req,
    input      [2:0] external_req,
    input      [2:0] start_floor,
    input      [1:0] jean_grey,
    output reg [2:0] current_floor,
    output           move_up,
    output           move_down,
    output           door_open
);
    // state encoding read by the testbench -- do not change these values
    // ! DO NOT CHANGE THESE VALUES
    localparam IDLE        = 2'd0;
    localparam MOVING_UP   = 2'd1;
    localparam MOVING_DOWN = 2'd2;
    localparam DOOR_OPEN   = 2'd3;

    // ! DO NOT CHANGE THESE DEFINITIONS OR NAMES
    reg [1:0] state;
    reg [2:0] target_floor;      // where you are moving to currently, 0 = none
    reg [1:0] door_timer;
    reg [2:0] pending_request;   // a request that arrived while busy, 0 = none

    // TODO (Parts B / C)
endmodule
