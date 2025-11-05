`timescale 1ns/1ps
// Uncomment the line below or define it in Quartus project settings
// `define USE_DCFIFO  

module lvds_serdes #(
    parameter PARALLEL_WIDTH = 8,
    parameter SERIAL_RATIO   = 8 
)(
    input  wire                        clk_sys,       // Parallel (system) domain clock
    input  wire                        clk_serial,    // Serial domain clock (faster)
    input  wire                        reset_n,

    // Transmit Interface (System domain)
    input  wire [PARALLEL_WIDTH-1:0]   tx_data_in,
    input  wire                        tx_data_valid,
    output wire                        tx_data_ready,

    // Receive Interface (System domain)
    output wire [PARALLEL_WIDTH-1:0]   rx_data_out,
    output wire                        rx_data_valid
);


// ----------------------------------------------- Internal Wires ------------------------------------------------
// Wires for clocks
wire clk_sys_pll;
wire clk_serial_pll;

// For the system clock to increase its frequency from 50 to 100
	pll pll_50to100_inst (
		.refclk   (clk_sys),   //  refclk.clk
		.rst      (reset_n),      //   reset.reset
		.outclk_0 (clk_sys_pll), // outclk0.clk
		.locked   (locked)    //  locked.export
	);

// For the system clock to increase its frequency from 50 to 400
		pll50to400mhz pll_50to400_inst (
		.refclk   (clk_serial),   //  refclk.clk
		.rst      (reset_n),      //   reset.reset
		.outclk_0 (clk_serial_pll), // outclk0.clk
		.locked   (locked)    //  locked.export
	);
// ----------------------------------------------- Internal Wires ------------------------------------------------
// TX Interface Inestantiation
wire [PARALLEL_WIDTH-1:0] tx_parallel_word;
wire                      tx_word_valid;

// Serializer Inestantiation
wire serializer_frame_pulse, tx_lvds_out_n, tx_lvds_out_p;

// Deserializer Inestantiation
wire serializer_rx_frame_pulse;

// RX Interface Inestantiation
wire [PARALLEL_WIDTH-1:0] deserialized_word;
wire                      deserializer_rx_frame_pulse;

// TX Interface Inestantiation
lvds_TX #(.PARALLEL_WIDTH(8), .SERIAL_RATIO(8)) tx1 (
    .clk_sys(clk_sys_pll),
    .reset_n(reset_n),
    
    // Transmit Interface (System domain) - INPUTS
    .tx_data_in(tx_data_in),
    .tx_data_valid(tx_data_valid),
    
    // Transmit Interface (System domain) - OUTPUTS
    .tx_data_ready(tx_data_ready),

    // Internal OUTPUTS to Serializer
    .tx_parallel_word(tx_parallel_word),
    .tx_word_valid(tx_word_valid),
    
    // Internal INPUTS to Serializer
    .ack_serial(serializer_frame_pulse) // CDC - Synched from SERIAL DOMAIN to SYSTEM DOMAIN
);

// Serializer Inestantiation
lvds_serializer #( .PARALLEL_WIDTH(8)) ser1 (
    .clk_serial(clk_serial_plls_pll),
    .reset_n(reset_n),

    // From TX (system domain synchronized)
    .tx_parallel_word(tx_parallel_word),
    .tx_word_valid(tx_word_valid),

    // To RX (frame alignment)
    .tx_frame_pulse(serializer_frame_pulse), // Pulse at start of serial transmission - To be synched to other domains

    // LVDS output
    .tx_lvds_out_n(tx_lvds_out_n),
    .tx_lvds_out_p(tx_lvds_out_p)
);

// Deserializer Inestantiation
lvds_deserializer #( .PARALLEL_WIDTH(8)) des1 (
    .clk_serial(clk_serial_plls_pll),
    .reset_n(reset_n),

    // From TX (system domain synchronized)
    // Pulse indicating that serializing begun, and deserailzing should start 
    .tx_frame_pulse(serializer_frame_pulse),    // CDC - Synched from SERIAL DOMAIN to SERIAL DOMAIN (IF FREQUENCY IS DIFFERENT) 
    
    .tx_lvds_out_p(tx_lvds_out_p),
    .tx_lvds_out_n(tx_lvds_out_n),

    // To RX (frame alignment)
    .deserialized_word(deserialized_word),       // Word that is deserialized
    // Pulse indicating that Deserializing is DONE 
    .rx_frame_pulse(deserializer_rx_frame_pulse) // CDC - Synched from SERIAL DOMAIN to SYSTEM DOMAIN
);

// RX Interface Inestantiation                               
lvds_RX #( .PARALLEL_WIDTH(8)) rx1 (  
    .clk_sys(clk_sys_pll),
    .reset_n(reset_n),

    // Receive Interface (System domain)
    .deserialized_word(deserialized_word),
    .rx_frame_pulse(deserializer_rx_frame_pulse), // CDC - Synched from SERIAL DOMAIN to SYSTEM DOMAIN

    // RX Interface Outputs
    .rx_data_out(rx_data_out),
    .rx_data_valid(rx_data_valid)
);


endmodule 