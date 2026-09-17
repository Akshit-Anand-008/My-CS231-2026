module rx_frame (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  data_in,
    input  wire        data_valid,

    output reg         frame_valid,
    output reg  [7:0]  dst_addr,
    output reg  [7:0]  src_addr,
    output reg  [63:0] payload
);

    // FSM States
    localparam IDLE      = 2'd0;
    localparam RX_DATA   = 2'd1;
    localparam CHECK_END = 2'd2;

    reg [1:0] state;
    
    // Counters and Registers
    reg [4:0] nibble_cnt;   // Counts 0 to 21 (22 nibbles = 11 bytes)
    reg [3:0] high_nibble;  // Holds the first half of a byte
    reg [79:0] frame_data;  // 80-bit shift register for {DST, SRC, PAYLOAD}
    reg [7:0] rx_crc_byte;  // Holds the 11th decoded byte

    // Bit Buffer (Gearbox)
    reg [15:0] bit_buf;
    reg [4:0]  buf_len;
    wire [7:0] new_byte = {high_nibble, dec_nib};
    wire [15:0] next_bit_buf = data_valid ? ((bit_buf << 8) | data_in) : bit_buf;
    wire [4:0]  next_buf_len = data_valid ? (buf_len + 5'd8) : buf_len;
    wire [4:0]  sym5         = (next_buf_len >= 5) ? next_bit_buf[next_buf_len - 1 -: 5] : 5'b0;

    // 4B/5B Decoder (Single Instance)
    wire [3:0] dec_nib;
    wire       dec_valid;
    decoder u_decoder (
        .encoded(sym5),
        .enable(1'b1),
        .data(dec_nib),
        .valid(dec_valid)
    );

    // CRC Engine
    reg        crc_rst;
    reg  [7:0] crc_data_in;
    reg        crc_data_valid;
    wire [7:0] calculated_crc;

    crc_parallel_serial #(
        .WIDTH(8), .POLY(8'hD5), .INIT(8'hFF), .DATA_WIDTH(8)
    ) rx_crc_inst (
        .clk(clk), .rst(crc_rst || rst),
        .data(crc_data_in), .data_valid(crc_data_valid),
        .data_last(1'b0), .crc(calculated_crc), .crc_valid()
    );

    // Main FSM
    always @(posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            buf_len        <= 5'd0;
            bit_buf        <= 16'd0;
            nibble_cnt     <= 5'd0;
            frame_valid    <= 1'b0;
            dst_addr       <= 8'h00;
            src_addr       <= 8'h00;
            payload        <= 64'h0;
            crc_rst        <= 1'b1;
            crc_data_valid <= 1'b0;
        end else begin
            // Defaults
            frame_valid    <= 1'b0;
            crc_rst        <= 1'b0;
            crc_data_valid <= 1'b0;
            bit_buf        <= next_bit_buf;
            buf_len        <= next_buf_len;

            case (state)
                IDLE: begin
                    crc_rst <= 1'b1; // Keep CRC reset between frames
                    if (next_buf_len >= 5) begin
                        if (sym5 == 5'b11000) begin // START marker
                            buf_len    <= next_buf_len - 5'd5;
                            nibble_cnt <= 5'd0;
                            state      <= RX_DATA;
                        end else begin
                            buf_len    <= next_buf_len - 5'd1; // Slide window by 1 bit
                        end
                    end
                end

                RX_DATA: begin
                    if (next_buf_len >= 5) begin
                        if (!dec_valid) begin // Invalid symbol -> abort
                            state <= IDLE;
                        end else begin
                            buf_len <= next_buf_len - 5'd5;
                            
                            if (nibble_cnt[0] == 1'b0) begin 
                                // Even nibble (Upper half of byte)
                                high_nibble <= dec_nib;
                                nibble_cnt  <= nibble_cnt + 5'd1;
                            end else begin 
                                if (nibble_cnt < 5'd20) begin
                                    // First 10 bytes: Shift into data register and feed to CRC
                                    frame_data     <= {frame_data[71:0], new_byte};
                                    crc_data_in    <= new_byte;
                                    crc_data_valid <= 1'b1;
                                end else begin
                                    // 11th byte: Store as received CRC
                                    rx_crc_byte <= new_byte;
                                end
                                
                                if (nibble_cnt == 5'd21) begin
                                    state <= CHECK_END; // All 22 nibbles received
                                end else begin
                                    nibble_cnt <= nibble_cnt + 5'd1;
                                end
                            end
                        end
                    end
                end

                CHECK_END: begin
                    if (next_buf_len >= 5) begin
                        buf_len <= next_buf_len - 5'd5;
                        
                        // Verify END marker and CRC match
                        if (sym5 == 5'b11001 && calculated_crc == rx_crc_byte) begin
                            // Unpack the 80-bit shift register into output ports
                            dst_addr    <= frame_data[79:72];
                            src_addr    <= frame_data[71:64];
                            payload     <= frame_data[63:0];
                            frame_valid <= 1'b1;
                        end
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule