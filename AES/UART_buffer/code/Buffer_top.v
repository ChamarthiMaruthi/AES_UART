
module Buffer_top(
    input        clk_3125_tx,    // UART TX clock
    input        clk_3125_rx,    // UART RX clock
	 input        reset,
    // ===== TX Management Ports =====
    input        parity_type,    // Parity type for UART TX
    input        tx_start,       // Start UART TX transmission (writes to FIFO)
    input  [7:0] ft_data,           // Data to transmit
    output       tx,        // UART TX output line
    output       tx_done,       // UART TX completion flag
	 output       tx_busy,
	 output       ft_full,
	 output       ft_empty,
	 output [7:0] ft_out,
	 output       rd_en,
	 input        wr_en,
	 
	 
    // ===== UART RX Management Ports =====
    input        rx,             // UART RX input line
    output [7:0] rx_msg,    // Data read from RX FIFO
    output       rx_parity,  // Parity read from RX FIFO
	 output       rx_complete,
    // ====== RX Management poarts ======
    input        rd_rx,
    input        wr_rx,
    output [7:0] dout,
    output       full,
    output       empty
);


// Corrected FIFO Instance
fifo_tx tx_fifo_inst (
    .clk_3125_tx(clk_3125_tx),
    .reset(reset),
    .wr_en(wr_en && !ft_full), // Correct: Check the internal wire
    .rd_en(rd_en),                // Correct: Driven by UART
    .ft_data(ft_data),
    .ft_out(ft_out),              // Correct: Connect to internal wire
    .ft_full(ft_full),
    .ft_empty(ft_empty)
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
    .rx_complete (rx_complete)
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
    .dout      (dout)
);

endmodule