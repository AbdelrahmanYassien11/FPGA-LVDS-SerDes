module lvds_TX #(
    parameter PARALLEL_WIDTH = 8,
    parameter SERIAL_RATIO   = 8 
)(
    input  wire                        clk_sys,       // Parallel (system) domain clock
    input  wire                        reset_n,

    // Transmit Interface (System domain)
    input  wire [PARALLEL_WIDTH-1:0]   tx_data_in,
    input  wire                        tx_data_valid,
    output reg                         tx_data_ready,

    // to serial domain
    output reg  [PARALLEL_WIDTH-1:0]   tx_parallel_word,
    output reg                         tx_word_valid,
    input wire                         ack_serial
);
    ff_synch #(.STAGES(2)) ff2_synch (
        .reset_n(reset_n),
        .sync_clock(clk_sys),
        .needs_to_be_synced(ack_serial),
        .sync_out(ack_serial_synched)
    );

    wire ack_serial_synched;

    // System domain (write)
    always@(posedge clk_sys or negedge reset_n) begin
        if(!reset_n) begin
            tx_data_ready    <= 1'b0;
            tx_parallel_word <= 0;
            tx_word_valid    <= 1'b0;
        end
        else if(tx_data_valid && tx_data_ready) begin
            tx_parallel_word <= tx_data_in;
            tx_word_valid    <= tx_data_valid;
            tx_data_ready    <= 1'b0;
        end
        else if(ack_serial_synched) begin
            tx_data_ready <= 1'b1;
        end
    end

endmodule 