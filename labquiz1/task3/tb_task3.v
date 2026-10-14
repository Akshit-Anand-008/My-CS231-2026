`timescale 1ns/1ns

// Elevator quiz testbench. Part A: 8 combinational checks. Part B: 6
// independent runs, each covering one or more [Test Item N] grading rows --
// every run forces the DUT straight into its starting state via setup()
// (Runs 1 and 6 excepted: they exercise a real rst / a real request
// sequence, since that's what they test). Part C: 3 short scenarios.
//
// Transcript columns: TIME (1ns after posedge) | STATE/OUTPUTS (after that
// posedge) | INPUTS (at that posedge). Checks only read state, target_floor,
// door_timer, pending_request -- all four are given in the stub template.

module tb;
    // Part A: floor_datapath on its own, no clock
    reg  [2:0] a_floor;
    reg        a_up, a_down;
    wire [2:0] a_next;
    floor_datapath dpa (.current_floor(a_floor), .move_up(a_up), .move_down(a_down), .next_floor(a_next));

    // Parts B/C: the elevator
    reg        clk, rst;
    reg  [1:0] jean_grey;
    reg  [2:0] internal_req, external_req, start_floor;
    wire [2:0] current_floor;
    wire       move_up, move_down, door_open;

    elevator dut (
        .clk(clk), .rst(rst),
        .internal_req(internal_req), .external_req(external_req),
        .start_floor(start_floor), .jean_grey(jean_grey),
        .current_floor(current_floor),
        .move_up(move_up), .move_down(move_down), .door_open(door_open)
    );

    always #5 clk = ~clk;

    // door-open observer: cap = floors opened at (3 bits each, oldest high),
    // door_n = count, door_bad = openings that weren't exactly 4 cycles
    reg  [23:0] cap;
    integer     door_n, door_len, door_bad;
    reg         door_prev, watching;
    always @(posedge clk) begin
        #1;
        if (watching) begin
            if (door_open && !door_prev) begin
                cap = (cap << 3) | current_floor; door_n = door_n + 1; door_len = 1;
            end else if (door_open) begin
                door_len = door_len + 1;
            end else if (!door_open && door_prev) begin
                if (door_len !== 4) door_bad = door_bad + 1;
                door_len = 0;
            end
        end
        door_prev = door_open;
    end

    reg [8*10:1] sname;
    always @(*) case (dut.state)
        2'd0: sname = "IDLE      ";
        2'd1: sname = "MOVING_UP ";
        2'd2: sname = "MOVING_DN ";
        2'd3: sname = "DOOR_OPEN ";
        default: sname = "????      ";
    endcase

    reg trace;
    always @(posedge clk) begin
        #1;
        if (trace)
            $display("t=%4d | %s floor=%0d up=%b dn=%b door=%b | int=%0d ext=%0d jg=%b",
                     $time, sname, current_floor, move_up, move_down, door_open,
                     internal_req, external_req, jean_grey);
    end

    task print_header;
        begin
            $display("TIME (1ns after posedge) | STATE/OUTPUTS (after that posedge) | INPUTS (at that posedge)");
            $display("-----------------------------------------------------------------------------------------");
        end
    endtask

    integer pass_a, pass_c;
    integer pass_reset, pass_opt, pass_move, pass_arrive, pass_doortiming,
            pass_targetclear, pass_priority, pass_latch, pass_bl;
    reg ok;
    reg [2:0] floor_before;

    task do_reset;
        input [2:0] sf;
        begin
            @(negedge clk);
            rst = 1; internal_req = 0; external_req = 0; jean_grey = 0; start_floor = sf;
            @(negedge clk);
            @(negedge clk);
            rst = 0;
            cap = 0; door_n = 0; door_len = 0; door_bad = 0; door_prev = 0;
            trace = 1; watching = 1;
        end
    endtask

    task step; input integer n; integer i; begin
        for (i = 0; i < n; i = i + 1) @(negedge clk);
    end endtask

    // bounded busy-waits so a stuck DUT fails instead of hanging the sim
    task wait_for_door_open;
        output ok; integer guard;
        begin
            ok = 1; guard = 0;
            while (!door_open && guard < 20) begin step(1); guard = guard + 1; end
            if (!door_open) ok = 0;
        end
    endtask

    task wait_while_door_open;
        output ok; integer guard;
        begin
            ok = 1; guard = 0;
            while (door_open && guard < 10) begin step(1); guard = guard + 1; end
            if (door_open) ok = 0;
        end
    endtask

    // force the DUT straight into (state, target_floor, current_floor,
    // pending_request, door_timer) -- all 5 are guaranteed stub names, so
    // this bypasses rst/earlier stimulus and keeps each run independent
    task setup;
        input [1:0] st; input [2:0] tf; input [2:0] cf; input [2:0] pend; input [1:0] dt;
        begin
            @(negedge clk);
            internal_req = 0; external_req = 0; jean_grey = 0;
            force dut.state           = st;
            force dut.target_floor    = tf;
            force dut.current_floor   = cf;
            force dut.pending_request = pend;
            force dut.door_timer      = dt;
            #1;
            release dut.state;
            release dut.target_floor;
            release dut.current_floor;
            release dut.pending_request;
            release dut.door_timer;
            cap = 0; door_n = 0; door_len = 0; door_bad = 0; door_prev = door_open;
            trace = 1; watching = 1;
        end
    endtask

    task jean_send3;
        input [1:0] s1, s2, s3;
        begin
            jean_grey = s1; step(1);
            jean_grey = s2; step(1);
            jean_grey = s3; step(1);
            jean_grey = 2'b00;
        end
    endtask

    task datapath_check;
        input [2:0] f; input u, d; input [2:0] exp;
        begin
            a_floor = f; a_up = u; a_down = d; #1;
            $display("  floor=%0d up=%b dn=%b -> next=%0d (exp %0d) | %s",
                     f, u, d, a_next, exp, (a_next === exp) ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
            if (a_next !== exp) pass_a = 0;
        end
    endtask

    task report;
        input [8*32:1] name;
        input [23:0]   got_cap;  input integer got_n;   input integer got_bad;
        input [23:0]   exp_cap;  input integer exp_n;
        output         res;
        begin
            res = (got_cap === exp_cap) && (got_n === exp_n) && (got_bad === 0);
            $display("  %0s: n=%0d cap=%o (exp n=%0d cap=%o) bad=%0d | %s",
                     name, got_n, got_cap, exp_n, exp_cap, got_bad, res ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        end
    endtask

    task check;
        input [8*64:1] label;
        input          cond;
        inout          integer flag;
        begin
            if (cond)
                $display("  %0s | \033[1;32mPASS\033[0m", label);
            else begin
                $display("  %0s | \033[1;31mFAIL\033[0m (state=%0d)", label, dut.state);
                flag = 0;
            end
        end
    endtask

    initial begin
        $dumpfile("task3.vcd");
        $dumpvars(0, tb);
        clk = 0; rst = 0; trace = 0; watching = 0;
        internal_req = 0; external_req = 0; jean_grey = 0; start_floor = 1;
        a_floor = 1; a_up = 0; a_down = 0;
        pass_a = 1; pass_c = 1;
        pass_reset = 1; pass_opt = 1; pass_move = 1; pass_arrive = 1;
        pass_doortiming = 1; pass_targetclear = 1; pass_priority = 1; pass_latch = 1;
        pass_bl = 1;

        // ---- PART A: floor_datapath -- middle floor x4 combos, both
        // saturation edges, and the two cells next to them ----
        $display("\n================ PART A ================");
        datapath_check(3'd3, 1, 0, 3'd4);
        datapath_check(3'd3, 0, 1, 3'd2);
        datapath_check(3'd3, 0, 0, 3'd3);
        datapath_check(3'd3, 1, 1, 3'd3);
        datapath_check(3'd7, 1, 0, 3'd7);
        datapath_check(3'd1, 0, 1, 3'd1);
        datapath_check(3'd6, 1, 0, 3'd7);
        datapath_check(3'd2, 0, 1, 3'd1);
        $display("  PART A: %s", pass_a ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");

        // ---- PART B: 6 independent runs ----
        $display("\n================ PART B ================");

        // silent warm-up reset: every DUT register (including any Part-C
        // memory register, whatever it's named) starts undriven (X) until
        // its first real rst. Without this, RUN 1's setup()-then-do_reset()
        // sequence leaves one real clock edge ticking on X state before the
        // first reset lands, and different (but equally correct) Part C
        // implementations can resolve that X differently -- turning a raw
        // trace line into a spurious transcript mismatch that has nothing
        // to do with Part B. One quiet pulse here settles it for good.
        @(negedge clk); rst = 1; @(negedge clk); @(negedge clk); rst = 0; @(negedge clk);

        $display("\n---- RUN 1: reset ----");
        print_header;
        setup(dut.MOVING_DOWN, 3'd3, 3'd6, 3'd5, 2'd2);
        do_reset(3'd3);
        check("\033[1;33m[Test Item 1]\033[0m reset #1",
              dut.state === dut.IDLE && current_floor === 3'd3 && dut.target_floor === 3'd0 &&
              dut.pending_request === 3'd0 && dut.door_timer === 2'd0 &&
              move_up === 1'b0 && move_down === 1'b0 && door_open === 1'b0,
              pass_reset);

        // async: pulse rst mid-cycle, nowhere near a clock edge
        setup(dut.MOVING_UP, 3'd6, 3'd3, 3'd4, 2'd1);
        @(negedge clk); #3;
        rst = 1;
        #1;
        check("\033[1;33m[Test Item 1]\033[0m reset #2",
              dut.state === dut.IDLE && current_floor === 3'd3 && dut.target_floor === 3'd0 &&
              dut.pending_request === 3'd0 && dut.door_timer === 2'd0 &&
              move_up === 1'b0 && move_down === 1'b0 && door_open === 1'b0,
              pass_reset);
        rst = 0;
        trace = 0; watching = 0;

        $display("\n---- RUN 2: start trip from IDLE ----");
        print_header;
        setup(dut.IDLE, 3'd0, 3'd4, 3'd0, 2'd0);
        external_req = 3'd6; step(1); external_req = 0;
        check("\033[1;33m[Test Item 8]\033[0m optimization #1", dut.target_floor === 3'd6, pass_opt);
        check("\033[1;33m[Test Item 2]\033[0m start #1", dut.state === dut.MOVING_UP && move_up === 1'b1, pass_move);

        setup(dut.IDLE, 3'd0, 3'd4, 3'd0, 2'd0);
        internal_req = 3'd1; step(1); internal_req = 0;
        check("\033[1;33m[Test Item 8]\033[0m optimization #2", dut.target_floor === 3'd1, pass_opt);
        check("\033[1;33m[Test Item 2]\033[0m start #2", dut.state === dut.MOVING_DOWN && move_down === 1'b1, pass_move);
        trace = 0; watching = 0;

        $display("\n---- RUN 3: arrive at target ----");
        print_header;
        setup(dut.MOVING_UP, 3'd5, 3'd5, 3'd0, 2'd0);   // current==target: arrival edge
        step(1);
        check("\033[1;33m[Test Item 3]\033[0m arrive #1", dut.state === dut.DOOR_OPEN, pass_arrive);
        check("\033[1;33m[Test Item 5]\033[0m target clear", dut.target_floor === 3'd0, pass_targetclear);
        wait_while_door_open(ok);
        check("\033[1;33m[Test Item 4]\033[0m door timing",
              ok && door_bad === 0 && dut.state === dut.IDLE, pass_doortiming);

        setup(dut.MOVING_DOWN, 3'd2, 3'd2, 3'd0, 2'd0);
        step(1);
        check("\033[1;33m[Test Item 3]\033[0m arrive #2", dut.state === dut.DOOR_OPEN, pass_arrive);

        setup(dut.IDLE, 3'd0, 3'd5, 3'd0, 2'd0);
        external_req = 3'd5; step(1); external_req = 0;
        check("\033[1;33m[Test Item 3]\033[0m arrive #3", dut.state === dut.DOOR_OPEN, pass_arrive);
        trace = 0; watching = 0;

        $display("\n---- RUN 4: internal beats external ----");
        print_header;
        setup(dut.IDLE, 3'd0, 3'd4, 3'd0, 2'd0);
        internal_req = 3'd2; external_req = 3'd5; step(1); internal_req = 0; external_req = 0;
        check("\033[1;33m[Test Item 6]\033[0m priority",
              dut.target_floor === 3'd2 && dut.state === dut.MOVING_DOWN, pass_priority);
        trace = 0; watching = 0;

        $display("\n---- RUN 5: request while busy ----");
        print_header;
        setup(dut.MOVING_DOWN, 3'd2, 3'd6, 3'd0, 2'd0);
        step(1);
        external_req = 3'd7; step(1); external_req = 0;
        check("\033[1;33m[Test Item 7]\033[0m latch #1",
              dut.pending_request === 3'd7 && dut.target_floor === 3'd2, pass_latch);
        external_req = 3'd1; step(1); external_req = 0;
        check("\033[1;33m[Test Item 7]\033[0m latch #2", dut.pending_request === 3'd7, pass_latch);

        wait_for_door_open(ok);
        if (!ok) pass_latch = 0;
        wait_while_door_open(ok);
        if (!ok) pass_latch = 0;
        check("\033[1;33m[Test Item 7]\033[0m latch #3",
              dut.state === dut.IDLE && dut.target_floor === 3'd0 && dut.pending_request === 3'd7, pass_latch);
        step(1);
        check("\033[1;33m[Test Item 7]\033[0m latch #4",
              dut.target_floor === 3'd7 && dut.state === dut.MOVING_UP && dut.pending_request === 3'd0, pass_latch);
        trace = 0; watching = 0;

        $display("\n---- RUN 6: long sequence ----");
        print_header;
        do_reset(3'd4);
        external_req = 3'd6; step(1); external_req = 0; step(15);
        internal_req = 3'd2; step(1); internal_req = 0; step(17);
        external_req = 3'd7; step(1); external_req = 0; step(19);
        internal_req = 3'd3; step(1); internal_req = 0; step(19);
        external_req = 3'd3; step(1); external_req = 0; step(10);
        trace = 0; watching = 0;
        report("\033[1;33m[Test Item 9]\033[0m seq", cap, door_n, door_bad, {3'd6,3'd2,3'd7,3'd3,3'd3}, 5, ok); pass_bl = ok;

        $display("\n================ SUMMARY: PART A + B ================");
        $display("  PART A                             : %s", pass_a           ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 1]\033[0m Reset                          : %s", pass_reset       ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 2]\033[0m IDLE -> UP/DOWN + move signals  : %s", pass_move        ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 3]\033[0m Reach target -> DOOR_OPEN       : %s", pass_arrive      ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 4]\033[0m Door opening timing             : %s", pass_doortiming  ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 5]\033[0m Target reset on door open       : %s", pass_targetclear ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 6]\033[0m Internal request priority       : %s", pass_priority    ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 7]\033[0m Latching pending request (busy) : %s", pass_latch       ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 8]\033[0m Direct request optimization     : %s", pass_opt         ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("  \033[1;33m[Test Item 9]\033[0m Long sequence, multiple reqs    : %s", pass_bl          ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("=====================================================");

        // split point for grading: everything below is Part C (bonus)
        $display("\n############################################################################");

        // ---- PART C: jean_grey's distress code -- 3 short scenarios ----
        $display("\n================ PART C ================");

        $display("\n---- C1: mid-trip trigger ----");
        print_header;
        do_reset(3'd3);
        external_req = 3'd6; step(1); external_req = 0;   // cycle 1: jg=00
        internal_req = 3'd1; step(1); internal_req = 0;   // cycle 2: jg=00; int1 latched (busy)
        step(1);                                          // cycle 3: jg=00 (guaranteed)
        jean_grey = 2'b01; step(1);
        jean_grey = 2'b10; step(1);
        check("C1 #1", dut.state !== dut.IDLE, pass_c);   // must not trigger on 2 symbols
        floor_before = dut.current_floor;
        jean_grey = 2'b01; step(1); jean_grey = 2'b00;    // 3rd symbol: 1+1+1=3 -> triggers
        check("C1 #2", dut.state === dut.IDLE && dut.current_floor === floor_before, pass_c);
        external_req = 3'd2; step(1); external_req = 0;
        check("C1 #3", dut.state !== dut.IDLE && dut.target_floor === 3'd2, pass_c);
        trace = 0; watching = 0;

        $display("\n---- C2: trigger during DOOR_OPEN ----");
        print_header;
        do_reset(3'd4);
        trace = 1; watching = 1;
        external_req = 3'd6; step(1); external_req = 0;   // short trip
        step(3);
        jean_send3(2'b11, 2'b00, 2'b01);                  // 2+0+1=3 -> triggers
        check("C2 #1", dut.state === dut.IDLE, pass_c);
        trace = 0; watching = 0;

        $display("\n---- C3: unbalanced code must not trigger ----");
        print_header;
        do_reset(3'd1);
        external_req = 3'd4; step(1); external_req = 0;
        step(2);
        jean_send3(2'b11, 2'b11, 2'b00);                  // 2+2+0=4 -> must NOT trigger
        step(6);
        trace = 0; watching = 0;
        report("C3", cap, door_n, door_bad, {3'd4}, 1, ok);
        if (!ok) pass_c = 0;

        $display("\n================ SUMMARY: PART C ================");
        $display("  PART C (optional, bonus)  : %s", pass_c ? "\033[1;32mPASS\033[0m" : "\033[1;31mFAIL\033[0m");
        $display("=================================================");
        $finish;
    end
endmodule
