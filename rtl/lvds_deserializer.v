
module lvds_deserializer #(
    parameter PARALLEL_WIDTH = 8
)(
    input  wire                        clk_serial,    // Fast serial clock
    input  wire                        reset_n,

    // From TX (system domain synchronized)
    input wire                        tx_frame_pulse,   // Pulse serializing begun, and deserailzing should start
    input wire                        tx_lvds_out_p,
    input wire                        tx_lvds_out_n,

    // To RX (frame alignment)
    output wire [PARALLEL_WIDTH-1:0]   deserialized_word,  // Word that is deserialized
    output wire                        rx_frame_pulse
);

//`define SER_DES_DIF_FREQ
`ifdef SER_DES_DIF_FREQ
    ff_synch #(.STAGES(2)) ff2_synch (
        .reset_n(reset_n),
        .sync_clock(clk_serial),
        .needs_to_be_synced(tx_frame_pulse),
        .sync_out(tx_frame_pulse_synched)
    );
`else
    assign tx_frame_pulse_synched = tx_frame_pulse;
`endif

    reg [PARALLEL_WIDTH-1:0]         parallel_word;
    reg [$clog2(PARALLEL_WIDTH)-1:0] bit_counter;
    reg                              serial_busy;
    reg                              rx_frame_pulse_reg;

    wire                             tx_frame_pulse_synched;

    always @(posedge clk_serial or negedge reset_n) begin
        if (!reset_n) begin
            parallel_word      <= {PARALLEL_WIDTH{1'b0}};
            bit_counter            <= 0;
            serial_busy            <= 1'b0;
            rx_frame_pulse_reg     <= 1'b0;
        end 
        else begin
            rx_frame_pulse_reg <= 1'b0;
            if (!serial_busy && tx_frame_pulse_synched) begin
                // Start a new frame
                bit_counter    <= PARALLEL_WIDTH - 1;
                serial_busy    <= 1'b1;
            end 
            else if (serial_busy) begin
                // Continue shifting
                parallel_word <= {parallel_word[PARALLEL_WIDTH-2:0], tx_lvds_out_p};
                if (bit_counter == 0) begin
                    serial_busy    <= 1'b0;
                    rx_frame_pulse_reg <= 1'b1;
                end
                else begin
                    bit_counter <= bit_counter - 1;
                end
            end
        end
    end

    assign rx_frame_pulse    = rx_frame_pulse_reg;
    assign deserialized_word = (rx_frame_pulse_reg? parallel_word:0);
    // assign deserialized_word = parallel_word;
endmodule

