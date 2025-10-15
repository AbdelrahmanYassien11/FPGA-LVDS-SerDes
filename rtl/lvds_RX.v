module lvds_RX #(
    parameter PARALLEL_WIDTH = 8,
    parameter SERIAL_RATIO   = 8
)(
    input  wire                        clk_sys,       // Parallel (system) domain clock
    input  wire                        reset_n,

    // Receive Interface (System domain)
    input  wire [PARALLEL_WIDTH-1:0]   deserialized_word,
    input  wire                        rx_frame_pulse,

    output wire [PARALLEL_WIDTH-1:0]   rx_data_out,
    output wire                        rx_data_valid
);

    ff_synch #(.STAGES(2)) ff2_synch (
        .reset_n(reset_n),
        .sync_clock(clk_sys),
        .needs_to_be_synced(rx_frame_pulse),
        .sync_out(rx_frame_pulse_synched)
    );
    
    reg [PARALLEL_WIDTH-1:0] rx_data_out_reg;
    reg                      rx_data_valid_reg;

    wire                     rx_frame_pulse_synched;

    always@(posedge clk_sys or negedge reset_n) begin
        if(!reset_n) begin
            rx_data_out_reg     <= 0;
            rx_data_valid_reg   <= 0;
        end
        else begin  
            rx_data_valid_reg   <= 0;
            if(rx_frame_pulse_synched) begin
                rx_data_out_reg     <= deserialized_word;
                rx_data_valid_reg   <= 1'b1;
            end
        end
    end

    assign rx_data_out      = rx_data_out_reg;
    assign rx_data_valid    = rx_data_valid_reg;


endmodule