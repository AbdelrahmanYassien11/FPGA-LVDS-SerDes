module lvds_serdes #(
    parameter PARALLEL_WIDTH = 8,
    parameter SERIAL_RATIO = 8  // 8:1 or 4:1 serialization
)(
    input  wire                        clk_sys,      // System clock (parallel side)
    input  wire                        clk_serial,   // Serial clock (faster)
    input  wire                        reset_n,
    
    // Serializer (Tx side)
    input  wire [PARALLEL_WIDTH-1:0]   tx_data_in,
    input  wire                        tx_data_valid,
    output wire                        tx_data_ready,
    output wire                        tx_lvds_out_p,
    output wire                        tx_lvds_out_n,
    
    // Deserializer (Rx side)
    input  wire                        rx_lvds_in_p,
    input  wire                        rx_lvds_in_n,
    output wire [PARALLEL_WIDTH-1:0]   rx_data_out,
    output wire                        rx_data_valid
);

// Parallel to serial converter
reg [PARALLEL_WIDTH-1:0] tx_shift_reg;
reg [3:0] bit_counter;
wire tx_serial_bit;

// Load parallel data
always @(posedge clk_sys or negedge reset_n) begin
    if (!reset_n) begin
        tx_shift_reg <= 0;
    end else if (tx_data_valid && tx_data_ready) begin
        tx_shift_reg <= tx_data_in;
    end
end

// Shift out bits at serial clock speed
always @(posedge clk_serial or negedge reset_n) begin
    if (!reset_n) begin
        bit_counter <= 0;
    end else begin
        bit_counter <= bit_counter + 1;
        tx_shift_reg <= {tx_shift_reg[PARALLEL_WIDTH-2:0], 1'b0};
    end
end

assign tx_serial_bit = tx_shift_reg[PARALLEL_WIDTH-1];

// LVDS differential output (differential pair)
assign tx_lvds_out_p = tx_serial_bit;
assign tx_lvds_out_n = ~tx_serial_bit;

assign tx_data_ready = (bit_counter == 0);

///////////////////////////////////////////////////
// Serial to parallel converter
reg [PARALLEL_WIDTH-1:0] rx_shift_reg;
reg [3:0] rx_bit_counter;
wire rx_serial_bit;

// Convert differential to single-ended
assign rx_serial_bit = rx_lvds_in_p; // Assuming LVDS receiver already converted

// Capture bits at serial clock speed
always @(posedge clk_serial or negedge reset_n) begin
    if (!reset_n) begin
        rx_shift_reg <= 0;
        rx_bit_counter <= 0;
    end else begin
        rx_shift_reg <= {rx_shift_reg[PARALLEL_WIDTH-2:0], rx_serial_bit};
        rx_bit_counter <= rx_bit_counter + 1;
    end
end

// Output parallel data when word complete
always @(posedge clk_serial or negedge reset_n) begin
    if (!reset_n) begin
        rx_data_out <= 0;
        rx_data_valid <= 0;
    end else if (rx_bit_counter == PARALLEL_WIDTH - 1) begin
        rx_data_out <= {rx_shift_reg[PARALLEL_WIDTH-2:0], rx_serial_bit};
        rx_data_valid <= 1;
    end else begin
        rx_data_valid <= 0;
    end
end

endmodule