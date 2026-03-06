
module Buffer_top(
    input        clk_3125_tx,    // UART TX clock
    input        clk_3125_rx,    // UART RX clock
	 input        reset,
    // ===== TX Management Ports =====
    input        parity_type,    // Parity type for UART TX
    //input        tx_start,       // Start UART TX transmission (writes to FIFO)
    input  [7:0] ft_data,           // Data to transmit
    output       tx,        // UART TX output line
    output       tx_done,       // UART TX completion flag
	 output       tx_busy,
	 output       ft_full,
	 output       ft_empty,
     output       ft_ready,
	 input        wr_en,
	 
	 
    // ===== UART RX Management Ports =====
    input        rx,             // UART RX input line
    output [7:0] rx_msg,    // Data read from RX FIFO
	output       rx_complete,
    output       rx_block_ok, // Signal that a full block of 16 bytes has been received
    // ====== RX Management poarts ======
    input        rd_rx,
    output        wr_rx,
    output [7:0] dout,
    output       full,
    output       empty
);

//wire tx_start;
reg rd_rx_d;
// Corrected FIFO Instance
wire ft_out;
wire rd_en;
wire [4:0] byte_counter;
wire rx_parity;

fifo_tx tx_fifo_inst (
    .clk_3125_tx(clk_3125_tx),
    .reset(reset),
    .wr_en(wr_en && !ft_full), // Correct: Check the internal wire
    .rd_en(rd_en),                // Correct: Driven by UART
    .ft_data(ft_data),
    .ft_out(ft_out),              // Correct: Connect to internal wire
    .ft_full(ft_full),
    .ft_empty(ft_empty),
    .ft_ready(ft_ready) // Not used in this design, but can be connected if needed
);



// Corrected UART TX Instance
uart_tx tx_inst (
    .clk_3125_tx(clk_3125_tx),
    .parity_type(parity_type),
    .tx_start(tx_start),            // 'tx_start' kicks off the process
    .ft_out(ft_out),             // UART gets its data from the FIFO output
    .tx(tx),                        // UART's final output goes to the module's 'tx' port
    .tx_done(tx_done),
    .ft_empty(ft_empty),       // Handshake
    .rd_en(rd_en),              // Handshake
	.tx_busy(tx_busy)
);
// ===== UART RX Instance =====
uart_rx rx_inst (
    .clk_3125_rx (clk_3125_rx),
    .rx          (rx),
    .rx_msg      (rx_msg),
    .rx_parity   (rx_parity),
    .rx_complete (rx_complete),
    .wr_rx       (wr_rx), // Connect the internal wire to the UART RX instance
    .byte_counter(byte_counter),
    .rx_block_ok (rx_block_ok)
);

// FIFO RX Instance
fifo_rx rx_fifo_inst (
    .clk_3125_rx (clk_3125_rx),
    .reset       (reset),
    .wr_rx       (wr_rx), // Write when RX is complete
    .rd_rx       (rd_rx),
    .din         (rx_msg),
    .full     (full),
    .empty    (empty),
    .dout      (dout),
    .rx_block_ok (rx_block_ok) // Connect the block ready signal to the FIFO
);

assign tx_start = ft_ready; // Start UART transmission when FIFO is ready (not full)

always @(posedge clk_3125_rx or posedge reset) begin
    if (reset) begin
        rd_rx_d <= 1'b0;
    end else begin
        rd_rx_d <= rd_rx;
    end
end


endmodule