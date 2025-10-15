module ff_synch #(
    parameter STAGES = 2  // Number of flip-flops in the synchronizer
)(
    input  wire sync_clock,
    input  wire reset_n,
    input  wire needs_to_be_synced,
    output wire sync_out
);

    // ============================================================
    // Multi-stage synchronizer shift register
    // ============================================================
    reg [STAGES-1:0] sync_chain;

    always @(posedge sync_clock or negedge reset_n) begin
        if (!reset_n) begin
            sync_chain <= {STAGES{1'b0}};
        end
        else begin
            sync_chain <= {sync_chain[STAGES-2:0], needs_to_be_synced};
        end
    end

    assign sync_out = sync_chain[STAGES-1];

endmodule
