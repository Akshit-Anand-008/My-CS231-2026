module tx_frame (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  dst_addr,
    input  wire [7:0]  src_addr,
    input  wire [63:0] payload,
    output reg  [7:0]  data_out,
    output reg         data_valid,
    output reg         busy
);

    // ------------------------------------------------------------------------
    // 1. Registered Inputs to Hold Active Frame Payload
    // ------------------------------------------------------------------------
    reg [7:0]  dst_reg;
    reg [7:0]  src_reg;
    reg [63:0] payload_reg;

    // ------------------------------------------------------------------------
    // 2. Purely Combinational CRC-8 over Active Frame Data
    // ------------------------------------------------------------------------
    wire [7:0]  curr_dst     = (start && !busy) ? dst_addr : dst_reg;
    wire [7:0]  curr_src     = (start && !busy) ? src_addr : src_reg;
    wire [63:0] curr_payload = (start && !busy) ? payload  : payload_reg;

    wire [79:0] raw_frame = {curr_dst, curr_src, curr_payload};
    wire [7:0]  crc_out;

    crc_parallel #(
        .WIDTH(8),
        .POLY(8'hD5),
        .DATA_WIDTH(80)
    ) tx_crc_inst (
        .crc_in(8'hFF),
        .data(raw_frame),
        .crc_out(crc_out)
    );

    // ------------------------------------------------------------------------
    // 3. Dynamic Byte Selection Mux
    // ------------------------------------------------------------------------
    reg [3:0] byte_sel;
    reg [7:0] active_byte;

    always @(*) begin
        case (byte_sel)
            4'd0:  active_byte = curr_dst;
            4'd1:  active_byte = curr_src;
            4'd2:  active_byte = curr_payload[63:56];
            4'd3:  active_byte = curr_payload[55:48];
            4'd4:  active_byte = curr_payload[47:40];
            4'd5:  active_byte = curr_payload[39:32];
            4'd6:  active_byte = curr_payload[31:24];
            4'd7:  active_byte = curr_payload[23:16];
            4'd8:  active_byte = curr_payload[15:8];
            4'd9:  active_byte = curr_payload[7:0];
            4'd10: active_byte = crc_out;
            default: active_byte = 8'h00;
        endcase
    end

    // ------------------------------------------------------------------------
    // 4. Single Shared Pair of Encoder Modules
    // ------------------------------------------------------------------------
    wire [4:0] enc_high_out;
    wire [4:0] enc_low_out;

    encoder enc_high (
        .data(active_byte[7:4]),
        .enable(1'b1),
        .encoded(enc_high_out)
    );

    encoder enc_low (
        .data(active_byte[3:0]),
        .enable(1'b1),
        .encoded(enc_low_out)
    );

    wire [9:0] encoded_symbol = {enc_high_out, enc_low_out};

    // ------------------------------------------------------------------------
    // 5. Zero-Latency Transmission State Machine
    // ------------------------------------------------------------------------
    reg [3:0]   tx_count;
    reg [119:0] frame_buf;

    always @(posedge clk) begin
        if (rst) begin
            busy        <= 1'b0;
            data_valid  <= 1'b0;
            data_out    <= 8'h00;
            tx_count    <= 4'd0;
            byte_sel    <= 4'd0;
            frame_buf   <= 120'b0;
            dst_reg     <= 8'h00;
            src_reg     <= 8'h00;
            payload_reg <= 64'b0;
        end else begin
            data_valid <= 1'b0;

            if (!busy) begin
                if (start) begin
                    busy        <= 1'b1;
                    tx_count    <= 4'd0;
                    byte_sel    <= 4'd1;
                    dst_reg     <= dst_addr;
                    src_reg     <= src_addr;
                    payload_reg <= payload;
                    
                    // Capture START marker and byte 0 encoding immediately on trigger
                    frame_buf   <= {5'b11000, encoded_symbol, 105'b0};
                end else begin
                    byte_sel    <= 4'd0;
                end
            end else begin
                if (tx_count < 4'd15) begin
                    data_out   <= frame_buf[119 - tx_count*8 -: 8];
                    data_valid <= 1'b1;
                    tx_count   <= tx_count + 4'd1;

                    if (byte_sel <= 4'd10) begin
                        case (byte_sel)
                            4'd1:  frame_buf[104:95] <= encoded_symbol;
                            4'd2:  frame_buf[94:85]  <= encoded_symbol;
                            4'd3:  frame_buf[84:75]  <= encoded_symbol;
                            4'd4:  frame_buf[74:65]  <= encoded_symbol;
                            4'd5:  frame_buf[64:55]  <= encoded_symbol;
                            4'd6:  frame_buf[54:45]  <= encoded_symbol;
                            4'd7:  frame_buf[44:35]  <= encoded_symbol;
                            4'd8:  frame_buf[34:25]  <= encoded_symbol;
                            4'd9:  frame_buf[24:15]  <= encoded_symbol;
                            4'd10: frame_buf[14:5]   <= encoded_symbol;
                        endcase
                        byte_sel <= byte_sel + 4'd1;
                    end else if (byte_sel == 4'd11) begin
                        frame_buf[4:0] <= 5'b11001; // Append END marker
                        byte_sel       <= 4'd12;
                    end
                end else begin
                    busy     <= 1'b0;
                    tx_count <= 4'd0;
                    byte_sel <= 4'd0;
                end
            end
        end
    end

endmodule