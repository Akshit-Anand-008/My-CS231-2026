// ============================================================================
// PART A: floor_datapath  (combinational)                       -- required
// ============================================================================
module floor_datapath (
    input      [2:0] current_floor,
    input            move_up,
    input            move_down,
    output     [2:0] next_floor
);
    wire up_only   = move_up   && !move_down;
    wire down_only = move_down && !move_up;

    assign next_floor = up_only   ? ((current_floor < 3'd7) ? current_floor + 3'd1 : 3'd7) :
                         down_only ? ((current_floor > 3'd1) ? current_floor - 3'd1 : 3'd1) :
                         current_floor;   // hold (also if both are asserted)
endmodule


// ============================================================================
// PART B: the FSM (ignore jean_grey)                            -- required
// PART C: jean_grey's distress code                              -- optional
// ============================================================================
module elevator (
    input            clk,
    input            rst,            // active-high, asynchronous
    input      [2:0] internal_req,   // 0 = no request; one-cycle pulse
    input      [2:0] external_req,   // 0 = no request; one-cycle pulse
    input      [2:0] start_floor,    // current_floor loaded from here on reset
    input      [1:0] jean_grey,      // one 2-bit symbol per cycle; used only in Part C
    output reg [2:0] current_floor,
    output           move_up,
    output           move_down,
    output           door_open
);
    localparam IDLE        = 2'd0;
    localparam MOVING_UP   = 2'd1;
    localparam MOVING_DOWN = 2'd2;
    localparam DOOR_OPEN   = 2'd3;

    reg  [1:0] state;
    reg  [2:0] target_floor;
    reg  [1:0] door_timer;
    reg  [2:0] pending_request;   // a request that arrived while busy, 0 = none

    // ---- Part C: jean_grey's distress code -------------------------------
    // Track the last 3 symbols (6 bits) in a shift register, and combinationally
    // check whether they contain exactly 3 ones (and so exactly 3 zeros).
    reg  [5:0] jean_hist;                        // the two previously stored symbols in the low 4 bits
    wire [5:0] jean_window = {jean_hist[3:0], jean_grey};   // last 3 symbols, including this one
    wire [2:0] jean_ones   = jean_window[0] + jean_window[1] + jean_window[2]
                            + jean_window[3] + jean_window[4] + jean_window[5];
    wire       jean_reset  = (jean_ones == 3'd3);   // exactly 3 ones among the 6 bits
    // -----------------------------------------------------------------------

    wire [2:0] next_floor;
    floor_datapath dp (
        .current_floor (current_floor),
        .move_up       (move_up),
        .move_down     (move_down),
        .next_floor    (next_floor)
    );

    // keep moving until the target is reached; jean_reset drops the move
    // outputs immediately so the car halts on the exact floor it is on.
    assign move_up   = (state == MOVING_UP)   && (current_floor < target_floor) && !jean_reset;
    assign move_down = (state == MOVING_DOWN) && (current_floor > target_floor) && !jean_reset;
    assign door_open = (state == DOOR_OPEN);

    // whichever request line is active this cycle; internal wins if both are
    wire [2:0] req_now = (internal_req != 3'd0) ? internal_req : external_req;
    // what IDLE should load: a request latched earlier wins over a fresh one
    wire [2:0] load_val = (pending_request != 3'd0) ? pending_request : req_now;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state             <= IDLE;
            target_floor      <= 3'd0;
            door_timer        <= 2'd0;
            pending_request   <= 3'd0;
            current_floor     <= start_floor;
            jean_hist         <= 6'd0;
        end else begin
            current_floor <= next_floor;   // the shaft moves the car (Part A)
            jean_hist     <= jean_window;  // shift in this cycle's symbol

            if (jean_reset) begin
                // exactly like rst, but current_floor is untouched -- the car
                // stops where it is, it does not teleport
                state           <= IDLE;
                target_floor    <= 3'd0;
                pending_request <= 3'd0;
                door_timer      <= 2'd0;
            end else begin
                case (state)
                    IDLE: begin
                        // whatever arrived earlier while busy (pending_request)
                        // takes priority; otherwise a fresh request goes
                        // straight to the target, no extra latching cycle
                        if (load_val != 3'd0) begin
                            target_floor    <= load_val;
                            pending_request <= 3'd0;
                            if (load_val == current_floor) begin
                                state        <= DOOR_OPEN;
                                target_floor <= 3'd0;
                                door_timer   <= 2'd0;
                            end else if (load_val > current_floor)
                                state <= MOVING_UP;
                            else
                                state <= MOVING_DOWN;
                        end
                    end

                    MOVING_UP, MOVING_DOWN: begin
                        if (current_floor == target_floor) begin
                            target_floor <= 3'd0;
                            door_timer   <= 2'd0;
                            state        <= DOOR_OPEN;
                        end else if (pending_request == 3'd0 && req_now != 3'd0) begin
                            pending_request <= req_now;
                        end
                    end

                    DOOR_OPEN: begin
                        if (pending_request == 3'd0 && req_now != 3'd0)
                            pending_request <= req_now;
                        if (door_timer == 2'd3) begin
                            door_timer <= 2'd0;
                            state      <= IDLE;
                        end else begin
                            door_timer <= door_timer + 2'd1;
                        end
                    end
                endcase
            end
        end
    end
endmodule
