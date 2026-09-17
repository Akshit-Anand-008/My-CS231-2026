module switch (
    input        clk,
    input        rst,

    input  [7:0] rx0_data,
    input        rx0_valid,
    input  [7:0] rx1_data,
    input        rx1_valid,
    input  [7:0] rx2_data,
    input        rx2_valid,
    input  [7:0] rx3_data,
    input        rx3_valid,

    output [7:0] tx0_data,
    output       tx0_valid,
    output [7:0] tx1_data,
    output       tx1_valid,
    output [7:0] tx2_data,
    output       tx2_valid,
    output [7:0] tx3_data,
    output       tx3_valid
);

    // =========================================================================
    // 1. RX Frame Receivers
    // =========================================================================
    wire        rx_frame_valid [0:3];
    wire [7:0]  rx_dst_addr    [0:3];
    wire [7:0]  rx_src_addr    [0:3];
    wire [63:0] rx_payload     [0:3];

    rx_frame rx0_inst (
        .clk(clk), .rst(rst),
        .data_in(rx0_data), .data_valid(rx0_valid),
        .frame_valid(rx_frame_valid[0]), .dst_addr(rx_dst_addr[0]),
        .src_addr(rx_src_addr[0]), .payload(rx_payload[0])
    );

    rx_frame rx1_inst (
        .clk(clk), .rst(rst),
        .data_in(rx1_data), .data_valid(rx1_valid),
        .frame_valid(rx_frame_valid[1]), .dst_addr(rx_dst_addr[1]),
        .src_addr(rx_src_addr[1]), .payload(rx_payload[1])
    );

    rx_frame rx2_inst (
        .clk(clk), .rst(rst),
        .data_in(rx2_data), .data_valid(rx2_valid),
        .frame_valid(rx_frame_valid[2]), .dst_addr(rx_dst_addr[2]),
        .src_addr(rx_src_addr[2]), .payload(rx_payload[2])
    );

    rx_frame rx3_inst (
        .clk(clk), .rst(rst),
        .data_in(rx3_data), .data_valid(rx3_valid),
        .frame_valid(rx_frame_valid[3]), .dst_addr(rx_dst_addr[3]),
        .src_addr(rx_src_addr[3]), .payload(rx_payload[3])
    );

    // =========================================================================
    // 2. Priority Ingress Selection
    // =========================================================================
    reg       active_frame_valid;
    reg [1:0] active_rx_port;

    always @(*) begin
        if (rx_frame_valid[0]) begin
            active_frame_valid = 1'b1;
            active_rx_port     = 2'd0;
        end else if (rx_frame_valid[1]) begin
            active_frame_valid = 1'b1;
            active_rx_port     = 2'd1;
        end else if (rx_frame_valid[2]) begin
            active_frame_valid = 1'b1;
            active_rx_port     = 2'd2;
        end else if (rx_frame_valid[3]) begin
            active_frame_valid = 1'b1;
            active_rx_port     = 2'd3;
        end else begin
            active_frame_valid = 1'b0;
            active_rx_port     = 2'd0;
        end
    end

    wire [7:0]  active_dst     = rx_dst_addr[active_rx_port];
    wire [7:0]  active_src     = rx_src_addr[active_rx_port];
    wire [63:0] active_payload = rx_payload[active_rx_port];

    // =========================================================================
    // 3. MAC Learning Table
    // =========================================================================
    wire [1:0] tbl_egress_port;
    wire       tbl_known_dest;

    switch_table #(
        .ADDR_WIDTH(8),
        .PORT_WIDTH(2),
        .TABLE_SIZE(8)
    ) mac_table (
        .clk(clk),
        .rst(rst),
        .src_addr(active_src),
        .dst_addr(active_dst),
        .ingress_port(active_rx_port),
        .frame_valid(active_frame_valid),
        .egress_port(tbl_egress_port),
        .known_destination(tbl_known_dest)
    );

    // =========================================================================
    // 4. Egress Control & Pure Combinational Trigger
    // =========================================================================
    reg [3:0] tx_start;
    wire [3:0] tx_busy;
    integer p;

    always @(*) begin
        tx_start = 4'b0000;
        if (active_frame_valid) begin
            if (tbl_known_dest) begin
                // Known destination: Send to egress port ONLY if it's not the ingress port
                if ((tbl_egress_port != active_rx_port) && !tx_busy[tbl_egress_port]) begin
                    tx_start[tbl_egress_port] = 1'b1;
                end
            end else begin
                // Unknown destination: Flood to all ports EXCEPT ingress port
                for (p = 0; p < 4; p = p + 1) begin
                    if ((p[1:0] != active_rx_port) && !tx_busy[p]) begin
                        tx_start[p] = 1'b1;
                    end
                end
            end
        end
    end

    // =========================================================================
    // 5. TX Instantiations
    // =========================================================================
    tx_frame tx0_inst (
        .clk(clk), .rst(rst),
        .start(tx_start[0]), .dst_addr(active_dst), .src_addr(active_src),
        .payload(active_payload), .data_out(tx0_data), .data_valid(tx0_valid), .busy(tx_busy[0])
    );

    tx_frame tx1_inst (
        .clk(clk), .rst(rst),
        .start(tx_start[1]), .dst_addr(active_dst), .src_addr(active_src),
        .payload(active_payload), .data_out(tx1_data), .data_valid(tx1_valid), .busy(tx_busy[1])
    );

    tx_frame tx2_inst (
        .clk(clk), .rst(rst),
        .start(tx_start[2]), .dst_addr(active_dst), .src_addr(active_src),
        .payload(active_payload), .data_out(tx2_data), .data_valid(tx2_valid), .busy(tx_busy[2])
    );

    tx_frame tx3_inst (
        .clk(clk), .rst(rst),
        .start(tx_start[3]), .dst_addr(active_dst), .src_addr(active_src),
        .payload(active_payload), .data_out(tx3_data), .data_valid(tx3_valid), .busy(tx_busy[3])
    );

endmodule