`timescale 1ns/1ns

// Question 1 testbench: mux2, mux4, mux4_bus, alu.
// Deterministic (no $random). Each section reports per-check results and a
// count; the final summary shows which parts pass. If you have only done some
// parts, the unfinished modules will show up as failing here.

module tb;
    // ---- part (a): mux2 ----
    reg  m2_a, m2_b, m2_sel;
    wire m2_y;
    mux2 dut_m2 (.a(m2_a), .b(m2_b), .sel(m2_sel), .y(m2_y));

    // ---- part (a): mux4 ----
    reg  [3:0] m4_d;
    reg  [1:0] m4_sel;
    wire       m4_y;
    mux4 dut_m4 (.d(m4_d), .sel(m4_sel), .y(m4_y));

    // ---- part (b): mux4_bus ----
    reg  [7:0] b0, b1, b2, b3;
    reg  [1:0] b_sel;
    wire [7:0] b_y;
    mux4_bus dut_bus (.d0(b0), .d1(b1), .d2(b2), .d3(b3), .sel(b_sel), .y(b_y));

    // ---- part (c): alu ----
    reg  [7:0] au_a, au_b;
    reg  [1:0] au_op;
    wire [7:0] au_y;
    alu dut_alu (.a(au_a), .b(au_b), .op(au_op), .y(au_y));

    integer i, j, t, k;
    integer f_m2, f_m4, f_bus, f_alu, f_alu_grid;
    reg [7:0] exp8;
    reg       exp1;
    reg [7:0] pat [0:7];

    task chk_m2;
        input a, b, s;
        begin
            m2_a = a; m2_b = b; m2_sel = s; #1;
            exp1 = s ? b : a;
            $display("  mux2  sel=%b a=%b b=%b -> y=%b (exp %b) | %s",
                     s, a, b, m2_y, exp1, (m2_y === exp1) ? "PASS" : "FAIL");
            if (m2_y !== exp1) f_m2 = f_m2 + 1;
        end
    endtask

    task chk_bus;
        input [1:0] s;
        begin
            b_sel = s; #1;
            case (s)
                2'd0: exp8 = b0;
                2'd1: exp8 = b1;
                2'd2: exp8 = b2;
                2'd3: exp8 = b3;
            endcase
            $display("  mux4_bus  sel=%0d buses={%h,%h,%h,%h} -> y=%h (exp %h) | %s",
                     s, b3, b2, b1, b0, b_y, exp8, (b_y === exp8) ? "PASS" : "FAIL");
            if (b_y !== exp8) f_bus = f_bus + 1;
        end
    endtask

    initial begin
        $dumpfile("task1.vcd");
        $dumpvars(0, tb);
        f_m2 = 0; f_m4 = 0; f_bus = 0; f_alu = 0; f_alu_grid = 0;

        // ============================================================
        $display("=== PART (a): mux2 -- all 8 input combinations ===");
        chk_m2(0,0,0); chk_m2(0,1,0); chk_m2(1,0,0); chk_m2(1,1,0);
        chk_m2(0,0,1); chk_m2(0,1,1); chk_m2(1,0,1); chk_m2(1,1,1);

        $display("");
        $display("=== PART (a): mux4 -- exhaustive, 16 data x 4 select = 64 cases ===");
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                m4_d = i[3:0]; m4_sel = j[1:0]; #1;
                if (m4_y !== m4_d[m4_sel]) begin
                    f_m4 = f_m4 + 1;
                    $display("  mux4  d=%b sel=%b -> y=%b (exp %b) | FAIL",
                             m4_d, m4_sel, m4_y, m4_d[m4_sel]);
                end
            end
        $display("  mux4: %0d/64 cases correct | %s", 64 - f_m4, (f_m4 == 0) ? "PASS" : "FAIL");

        // ============================================================
        $display("");
        $display("=== PART (b): mux4_bus -- directed (distinct bus per port) ===");
        b0 = 8'hDE; b1 = 8'hAD; b2 = 8'hBE; b3 = 8'hEF;
        chk_bus(0); chk_bus(1); chk_bus(2); chk_bus(3);

        $display("");
        $display("=== PART (b): mux4_bus -- sweep, 8 patterns rotated over 4 ports, all selects ===");
        pat[0] = 8'h00; pat[1] = 8'hFF; pat[2] = 8'hAA; pat[3] = 8'h55;
        pat[4] = 8'h0F; pat[5] = 8'hF0; pat[6] = 8'h3C; pat[7] = 8'h81;
        for (t = 0; t < 8; t = t + 1) begin
            b0 = pat[t]; b1 = pat[(t+1) % 8]; b2 = pat[(t+2) % 8]; b3 = pat[(t+3) % 8];
            for (k = 0; k < 4; k = k + 1) chk_bus(k[1:0]);
        end

        // ============================================================
        $display("");
        $display("=== PART (c): alu -- directed (wraparound, borrow) ===");
        au_a = 8'd200; au_b = 8'd100; au_op = 2'b00; #1;
        $display("  add : 200+100 -> %0d (exp 44)  | %s", au_y, (au_y===8'd44)?"PASS":"FAIL");
        if (au_y !== 8'd44) f_alu = f_alu + 1;
        au_a = 8'd10; au_b = 8'd25; au_op = 2'b01; #1;
        $display("  sub : 10-25   -> %0d (exp 241) | %s", au_y, (au_y===8'd241)?"PASS":"FAIL");
        if (au_y !== 8'd241) f_alu = f_alu + 1;
        au_a = 8'hF0; au_b = 8'h0F; au_op = 2'b10; #1;
        $display("  and : F0&0F   -> %h (exp 00) | %s", au_y, (au_y===8'h00)?"PASS":"FAIL");
        if (au_y !== 8'h00) f_alu = f_alu + 1;
        au_a = 8'hF0; au_b = 8'h0F; au_op = 2'b11; #1;
        $display("  or  : F0|0F   -> %h (exp FF) | %s", au_y, (au_y===8'hFF)?"PASS":"FAIL");
        if (au_y !== 8'hFF) f_alu = f_alu + 1;

        $display("");
        $display("=== PART (c): alu -- grid, 6 x 6 operands x 4 ops = 144 cases ===");
        for (i = 0; i < 6; i = i + 1)
            for (j = 0; j < 6; j = j + 1)
                for (k = 0; k < 4; k = k + 1) begin
                    case (i) 0: au_a=8'h00; 1: au_a=8'h01; 2: au_a=8'h7F; 3: au_a=8'h80; 4: au_a=8'hC3; 5: au_a=8'hFF; endcase
                    case (j) 0: au_b=8'h00; 1: au_b=8'h01; 2: au_b=8'h7F; 3: au_b=8'h80; 4: au_b=8'hC3; 5: au_b=8'hFF; endcase
                    au_op = k[1:0]; #1;
                    case (au_op)
                        2'd0: exp8 = au_a + au_b;
                        2'd1: exp8 = au_a - au_b;
                        2'd2: exp8 = au_a & au_b;
                        2'd3: exp8 = au_a | au_b;
                    endcase
                    if (au_y !== exp8) begin
                        f_alu = f_alu + 1;
                        f_alu_grid = f_alu_grid + 1;
                        $display("  alu  a=%h b=%h op=%0d -> y=%h (exp %h) | FAIL", au_a, au_b, au_op, au_y, exp8);
                    end
                end
        $display("  alu grid: %0d/144 cases correct | %s", 144 - f_alu_grid, (f_alu_grid == 0) ? "PASS" : "FAIL");

        // ============================================================
        $display("");
        $display("=== SUMMARY ===");
        $display("  part (a) mux2     : %s", (f_m2  == 0) ? "PASS" : "FAIL");
        $display("  part (a) mux4     : %s", (f_m4  == 0) ? "PASS" : "FAIL");
        $display("  part (b) mux4_bus : %s", (f_bus == 0) ? "PASS" : "FAIL");
        $display("  part (c) alu      : %s", (f_alu == 0) ? "PASS" : "FAIL");

        $finish;
    end
endmodule
