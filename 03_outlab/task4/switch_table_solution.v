module switch_table #(
    parameter ADDR_WIDTH = 8,
    parameter PORT_WIDTH = 2,
    parameter TABLE_SIZE = 8
) (
    input                           clk,
    input                           rst,

    input  [ADDR_WIDTH-1:0]         src_addr,
    input  [ADDR_WIDTH-1:0]         dst_addr,
    input  [PORT_WIDTH-1:0]         ingress_port,
    input                           frame_valid,

    output reg [PORT_WIDTH-1:0]     egress_port,
    output reg                      known_destination
);

    // Array declarations
    reg [ADDR_WIDTH-1:0] table_addrs [0:TABLE_SIZE-1];
    reg [PORT_WIDTH-1:0] table_ports [0:TABLE_SIZE-1];
    reg                  table_valid [0:TABLE_SIZE-1];

    integer i;
    reg     handled; // A flag to track if we found a match or empty slot

    // 1. Sequential logic for learning/updating the table
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                table_valid[i] <= 1'b0;
            end
        end else if (frame_valid) begin
            handled = 1'b0; // Reset flag at the start of the cycle
            
            // Pass 1: Try to find and update an existing entry
            for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                if (table_valid[i] && (table_addrs[i] == src_addr)) begin
                    table_ports[i] <= ingress_port;
                    handled = 1'b1;
                end
            end
            
            // Pass 2: If not found, find the first empty slot to allocate
            if (!handled) begin
                for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                    if (!table_valid[i] && !handled) begin
                        table_valid[i] <= 1'b1;
                        table_addrs[i] <= src_addr;
                        table_ports[i] <= ingress_port;
                        handled = 1'b1; // Prevent filling multiple empty slots
                    end
                end
            end
        end
    end
    
    // 2. Combinational logic for destination lookup
    always @(*) begin
        known_destination = 1'b0;
        egress_port       = {PORT_WIDTH{1'b0}};

        for (i = 0; i < TABLE_SIZE; i = i + 1) begin
            if (table_valid[i] && (table_addrs[i] == dst_addr)) begin
                known_destination = 1'b1;
                egress_port       = table_ports[i];
            end
        end
    end

endmodule