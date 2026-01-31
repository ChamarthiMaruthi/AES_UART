`timescale 1ns/1ns

module tb;

    // ==============================
    // Clocks & Reset
    // ==============================
    reg clk_100;
    reg clk_3125_tx;
    reg clk_3125_rx;
    reg rst_n;
    reg rst_n_slow = 1;
    reg rst_n_fast = 1;

    // ==============================
    // DUT I/O
    // ==============================
    reg         start = 0;
    reg [127:0] plaintext;
    reg [127:0] key;

    wire [127:0] decrypted_text;
    wire         done;
    wire         RD_RX;

    wire tx;
    reg rx;

    // CDC //
    wire done_slow;
    wire enc_done;
    wire fifo_wr_en;
    wire fifo_wr_pulse;
    //wire tx_active;
    wire enc_done_toggle;
    wire tx_start_1;
    wire storage_done;
    //assign rx = tx; // UART loopback

    // ==============================
    // DUT
    // ==============================
    aes_uart_top dut (
        .clk_100        (clk_100),
        .clk_3125_tx    (clk_3125_tx),
        .clk_3125_rx    (clk_3125_rx),
        .rst_n          (rst_n),
        .start          (start),
        .plaintext      (plaintext),
        .key            (key),
        .decrypted_text (decrypted_text),
        .done            (done),
        .tx              (tx),
        .rx              (rx),
        .enc_done       (enc_done),
		.done_slow       (done_slow),
        .rst_n_slow     (rst_n_slow),
        .rst_n_fast     (rst_n_fast),
        .RD_RX          (RD_RX),
        .fifo_wr_en     (fifo_wr_en),
        .fifo_wr_pulse  (fifo_wr_pulse),
        //.tx_active      (tx_active),
        .enc_done_toggle(enc_done_toggle),
        .tx_start_1     (tx_start_1),
        .storage_done   (storage_done)
    );

    always @(*) begin
        rx = tx;
    end

    // ==============================
    // Clock generation
    // ==============================
    initial begin
        clk_100 = 1;
        forever #5 clk_100 = ~clk_100;
    end

    initial begin
        clk_3125_tx = 1;
        forever #160 clk_3125_tx = ~clk_3125_tx;
    end

    initial begin
        clk_3125_rx = 0;
        forever #160 clk_3125_rx = ~clk_3125_rx;
    end

    // ==============================
    // Reset
    // ==============================
    initial begin
        rst_n = 1;
        start = 0;
        plaintext = 0;
        key = 0;
        //#20;
        //rst_n = 0;
        rst_n_fast = 1;
        rst_n_slow = 1;
        #10;
        rst_n_fast = 0;
        //#100
        rst_n_slow = 0;
    end

    // ==============================
    // Protocol Monitors
    // ==============================

    // Example: tx_start must not assert before encryption completes
    /*always @(posedge clk_3125_tx) begin
        if (dut.u_uart_buffer.tx_start && !dut.u_aes_encrypt.done) begin
            $fatal(1, "ERROR: tx_start asserted before encryption completed at time %t", $time);
        end
    end*/

    // FIFO underflow check
    always @(posedge clk_3125_tx) begin
        if (dut.u_uart_buffer.rd_en && dut.u_uart_buffer.ft_empty) begin
            $fatal(1, "ERROR: FIFO_TX underflow at time %t", $time);
        end
    end

    // FIFO overflow check
    always @(posedge clk_3125_tx) begin
        if (dut.u_uart_buffer.wr_en && dut.u_uart_buffer.ft_full) begin
            $fatal(1, "ERROR: FIFO_TX overflow at time %t", $time);
        end
    end

    // RX FIFO underflow
    /*always @(posedge clk_3125_rx) begin
        if (dut.u_uart_buffer.rd_rx && dut.u_uart_buffer.empty) begin
            $fatal(1, "ERROR: FIFO_RX underflow at time %t", $time);
        end
    end*/

    // ==============================
    // Test Sequence
    // ==============================
    initial begin
        //wait(rst_n == 1);

        //@(posedge clk_100);
        plaintext = 128'h00000000000000000000000000000000;
        key       = 128'h00000000000000000000000000000000;

        @(posedge clk_100);
        start = 1;
        @(posedge clk_100);
        start = 0;

        // Wait for system completion
        wait(done);

        // Final correctness check
        if (decrypted_text !== plaintext) begin
            //$fatal(1, "Time:%0t, FAIL: Decrypted text mismatch. Expected=%h Got=%h", $time, plaintext, decrypted_text);
            $display("FAIL: End-to-end AES→UART→AES verification failed at time %t", $time);
            $display("Expected=%h Got=%h", plaintext, decrypted_text);
            $finish;
        end else begin
            $display("PASS: End-to-end AES→UART→AES verified at time %t", $time);
            $finish;
        end

        //#1000;
        //$finish;
    end

endmodule

