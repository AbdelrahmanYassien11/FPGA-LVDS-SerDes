module lvds_serializer #(
    parameter PARALLEL_WIDTH = 8
)(
    input  wire                        clk_serial,    // Fast Serial Clock
    input  wire                        reset_n,

    // From TX (system domain synchronized)
    input  wire [PARALLEL_WIDTH-1:0]   tx_parallel_word,
    input  wire                        tx_word_valid,   // Pulse indicating a new word to serialize

    // To RX (frame alignment)
    output reg                         tx_frame_pulse,  // Pulse at start of serial transmission

    // LVDS output
    output wire                        tx_lvds_out_p,
    output wire                        tx_lvds_out_n
);

    ff_synch #(.STAGES(2)) ff2_synch (
        .reset_n(reset_n),
        .sync_clock(clk_serial),
        .needs_to_be_synced(tx_word_valid),
        .sync_out(tx_word_valid_synched)
    );

    reg [PARALLEL_WIDTH-1:0]        shift_reg;
    reg [$clog2(PARALLEL_WIDTH):0]  bit_counter;
    reg                             serial_busy;

    wire                            tx_word_valid_synched;

    always @(posedge clk_serial or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg      <= {PARALLEL_WIDTH{1'b0}};
            bit_counter    <= 0;
            serial_busy    <= 1'b0;
            tx_frame_pulse <= 1'b0;
        end 
        else begin
            tx_frame_pulse <= 1'b0; // default low

            if (!serial_busy && tx_word_valid_synched) begin
                // Start a new frame
                shift_reg      <= tx_parallel_word;
                bit_counter    <= PARALLEL_WIDTH - 1;
                serial_busy    <= 1'b1;
                tx_frame_pulse <= 1'b1;  // one-cycle start pulse
            end 
            else if (serial_busy) begin
                // Continue shifting
                shift_reg <= {shift_reg[PARALLEL_WIDTH-2:0], 1'b0};
                if (bit_counter == 0) begin
                    serial_busy <= 1'b0;
                end
                else begin
                    bit_counter <= bit_counter - 1;
                end
            end
        end
    end

    // Output the MSB as the serial bit
    assign tx_lvds_out_p = shift_reg[PARALLEL_WIDTH-1];
    assign tx_lvds_out_n = ~tx_lvds_out_p;

endmodule
