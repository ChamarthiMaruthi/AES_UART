`timescale 1ns/1ps

module tb_top;

    // Instantiate UART main testbench
    tb uart_tb();

    // Instantiate FIFO testbench
    fifo_tx_tb fifo_tb();

endmodule

