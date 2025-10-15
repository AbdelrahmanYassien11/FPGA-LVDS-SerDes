`timescale 1ns/1ps
// Uncomment the line below or define it in Quartus project settings
// `define USE_DCFIFO  

module lvds_serdes #(
    parameter PARALLEL_WIDTH = 8,
    parameter SERIAL_RATIO   = 8   // e.g., 8:1 serialization
)(
    input  wire                        clk_sys,       // Parallel (system) domain clock
    input  wire                        clk_serial,    // Serial domain clock (faster)
    input  wire                        reset_n,

    // Transmit Interface (System domain)
    input  wire [PARALLEL_WIDTH-1:0]   tx_data_in,
    input  wire                        tx_data_valid,
    output reg                        tx_data_ready,
    output wire                        tx_lvds_out_p,
    output wire                        tx_lvds_out_n,

    // Receive Interface (System domain)
    input  wire                        rx_lvds_in_p,
    input  wire                        rx_lvds_in_n,
    output wire [PARALLEL_WIDTH-1:0]   rx_data_out,
    output wire                        rx_data_valid
);

    // ============================================================
    // 1. Clock Domain Crossing for TX path (clk_sys -> clk_serial)
    // ============================================================
`ifdef USE_DCFIFO
    // ---------- DCFIFO-BASED CDC ----------
    wire [PARALLEL_WIDTH-1:0] tx_fifo_out;
    wire tx_fifo_empty;

    dcfifo #(
        .lpm_width(PARALLEL_WIDTH),
        .lpm_numwords(16),
        .lpm_showahead("OFF"),
        .overflow_checking("ON"),
        .underflow_checking("ON"),
        .use_eab("ON")
    ) tx_dcfifo (
        .wrclk(clk_sys),
        .wrreq(tx_data_valid),
        .data(tx_data_in),
        .wrfull(),

        .rdclk(clk_serial),
        .rdreq(~tx_fifo_empty),
        .q(tx_fifo_out),
        .rdempty(tx_fifo_empty),

        .aclr(~reset_n)
    );

    assign tx_data_ready = 1'b1;  // Always ready when FIFO not full

    wire [PARALLEL_WIDTH-1:0] tx_parallel_word = tx_fifo_out;
    wire tx_word_valid = ~tx_fifo_empty;

`else

    // System domain (write)
    always@(posedge clk_sys or negedge reset_n) begin
        if(!reset_n) begin
            tx_data_ready <= 0;
        end
        else if(tx_data_valid && tx_data_ready) begin
            tx_buffer <= tx_data_in;

        end
        else begin
            tx_buffer <= tx_buffer;
        end
    end

    always@(posedge clk_serial or negedge reset_n) begin
        if(!reset_n) begin
            tx_data_ready <= 0;
        end
        else if() begin
            req_serial_sync1 <= tx_data_valid;
            req_serial_sync2 <= req_serial_sync1;
            tx_serial_domain_data <= tx_buffer;

        end
    end


    // ---------- HANDSHAKE-BASED CDC ----------
    reg [PARALLEL_WIDTH-1:0] tx_buffer;
    reg req, ack_sys_sync1, ack_sys_sync2;
    reg [PARALLEL_WIDTH-1:0] tx_serial_domain_data;
    reg req_serial_sync1, req_serial_sync2;
    reg ack_serial;

    // System domain (accepting parallel output into buffer)
    always @(posedge clk_sys or negedge reset_n) begin
        if (!reset_n) begin
            tx_buffer     <= 0;
            tx_data_ready <= 1;
        end 
        else if (tx_data_valid && tx_data_ready) begin
            tx_buffer <= tx_data_in;
            tx_data_ready <= 1'b0;
        end 
        //checking if the synched ack from serial domain is asserted to point out that the data frame has been accepted by the serial side
        else if (ack_sys_sync2) begin
            tx_data_ready <= 1'b1;
        end
    end

    //Synch Signals & Serial Domain
    always@(posedge clk_serial or negedge reset_n) begin
        if(~reset_n) begin
            req_serial_sync1 <= 0;
            req_serial_sync2 <= 0;
            ack_serial       <= 0;
        end
        else begin
            req_serial_sync1 <= tx_data_ready;
            req_serial_sync2 <= req_serial_sync1;
            if(req_serial_sync2 && !ack_serial) begin
                tx_serial_domain_data <= tx_buffer;
                ack_serial            <= 1'b1;
            end
            else if(!req_serial_sync2) begin
                ack_serial <= 1'b0;
            end
        end
    end

    // Synch Serial Domain ack back to system domain
    always @(posedge clk_sys or negedge reset_n) begin
        if (!reset_n) begin
            ack_sys_sync1 <= 1'b0;
            ack_sys_sync2 <= 1'b0;
        end else begin
            ack_sys_sync1 <= ack_serial;
            ack_sys_sync2 <= ack_sys_sync1;
        end
    end

    wire [PARALLEL_WIDTH-1:0] tx_parallel_word = tx_serial_domain_data;
    wire tx_word_valid = ack_serial;

`endif

    // ============================================================
    // 2. Serializer (Parallel → Serial)
    // ============================================================
    reg [PARALLEL_WIDTH-1:0] tx_shift_reg;
    reg [$clog2(PARALLEL_WIDTH)-1:0] bit_counter;

    always @(posedge clk_serial or negedge reset_n) begin
        if (!reset_n) begin
            tx_shift_reg <= 0;
            bit_counter  <= 0;
        end 
        else if (tx_word_valid && bit_counter == 0) begin
            tx_shift_reg <= tx_parallel_word;
            bit_counter  <= PARALLEL_WIDTH - 1;
        end 
        else if (bit_counter != 0) begin
            tx_shift_reg <= {tx_shift_reg[PARALLEL_WIDTH-2:0], 1'b0};
            bit_counter  <= bit_counter - 1;
        end
    end

    wire tx_serial_bit = tx_shift_reg[PARALLEL_WIDTH-1];
    assign tx_lvds_out_p = tx_serial_bit;
    assign tx_lvds_out_n = ~tx_serial_bit;

    // Synchronize tx_word_valid into serial domain
    reg tx_word_valid_sync1, tx_word_valid_sync2;
    always @(posedge clk_serial or negedge reset_n) begin
        if (!reset_n) begin
            tx_word_valid_sync1 <= 0;
            tx_word_valid_sync2 <= 0;
        end 
        else begin
            tx_word_valid_sync1 <= tx_word_valid;
            tx_word_valid_sync2 <= tx_word_valid_sync1;
        end
    end

    wire tx_word_valid_rx = tx_word_valid_sync2;

    // Generate rx_word_valid to gate deserialization
    reg rx_word_valid;
    always @(posedge clk_serial or negedge reset_n) begin
        if (!reset_n) begin
            rx_word_valid <= 1'b0;
        end
        else if (tx_word_valid_rx) begin
            rx_word_valid <= 1'b1;
        end
        else begin
            rx_word_valid <= 1'b0;
        end
    end

    // ============================================================
    // 3. Deserializer (Serial → Parallel)
    // ============================================================
    reg [PARALLEL_WIDTH-1:0] rx_shift_reg;
    reg [$clog2(PARALLEL_WIDTH)-1:0] rx_bit_counter;
    reg [PARALLEL_WIDTH-1:0] rx_parallel_word;
    reg rx_parallel_valid;

    wire rx_serial_bit = rx_lvds_in_p; // Simplified; LVDS receiver assumed external

    always @(posedge clk_serial or negedge reset_n) begin
        if (!reset_n) begin
            rx_shift_reg <= 0;
            rx_bit_counter <= 0;
            rx_data_valid  <= 0;
        end 
        else if(rx_word_valid) begin
            rx_shift_reg   <= {rx_shift_reg[PARALLEL_WIDTH-2:0], rx_serial_bit};
            if(rx_bit_counter == PARALLEL_WIDTH - 1) begin
                rx_data_valid  <= 1;
                rx_bit_counter <= 0;
            end
            else begin
                rx_bit_counter <= rx_bit_counter + 1;
                rx_data_valid  <= 0;
            end
        end
    end

    // ============================================================
    // 4. (Optional) CDC for RX back to clk_sys domain
    // ============================================================
`ifdef USE_DCFIFO
    dcfifo #(
        .lpm_width(PARALLEL_WIDTH),
        .lpm_numwords(16),
        .lpm_showahead("OFF"),
        .overflow_checking("ON"),
        .underflow_checking("ON"),
        .use_eab("ON")
    ) rx_dcfifo (
        .wrclk(clk_serial),
        .wrreq(rx_parallel_valid),
        .data(rx_parallel_word),
        .wrfull(),

        .rdclk(clk_sys),
        .rdreq(1'b1),
        .q(rx_data_out),
        .rdempty(),

        .aclr(~reset_n)
    );

    assign rx_data_valid = rx_parallel_valid;  // Approximation for top-level visibility

`else
    // Simple handshake-free (unsafe if high throughput)
    reg [PARALLEL_WIDTH-1:0] rx_sys_domain;
    reg rx_valid_sys;

    always @(posedge clk_sys or negedge reset_n) begin
        if (!reset_n) begin
            rx_sys_domain <= 0;
            rx_valid_sys <= 1'b0;
        end else if (rx_parallel_valid) begin
            rx_sys_domain <= rx_parallel_word;
            rx_valid_sys <= 1'b1;
        end else begin
            rx_valid_sys <= 1'b0;
        end
    end

    assign rx_data_out = rx_sys_domain;
    assign rx_data_valid = rx_valid_sys;
`endif

endmodule
