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
    wire         WR_RX;

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
        .WR_RX          (WR_RX),
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


    // ============================================================
    // DRIVER
    // ============================================================
    task aes_send_block(input [127:0] pt, input [127:0] k);
    begin
        //@(posedge clk);
        plaintext <= pt;
        key       <= k;
        start     <= 1'b1;

        @(posedge clk_100);
        start     <= 1'b0;
    end
    endtask

    // ============================================================
    // SCOREBOARD
    // ============================================================
    integer i = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // latency / handshake tracking
    integer latency_cnt = 0;
    integer latency_ref = 11;
    integer latency_err = 0;
    reg     in_flight = 0;
    reg     done_d = 0;
    reg [127:0] pt_prev;

    // ============================================================
    // MONITOR + CHECKERS
    // ============================================================
    always @(posedge clk_100) begin
        done_d <= done;

        if (!rst_n) begin
            latency_cnt <= 0;
            in_flight   <= 0;
            pt_prev     <= plaintext;
        end else begin

            // start handshake
            if (start && !in_flight) begin
                in_flight   <= 1;
                latency_cnt <= 0;
            end

            if (in_flight && !done)
                latency_cnt <= latency_cnt + 1;

            // done handshake
            if (done && in_flight) begin
                in_flight <= 0;
                $display("time : %0t | Entered done handshake block. pt=%h", $time, plaintext);
                

                if (latency_cnt != latency_ref) begin
                    latency_err <= latency_err + 1;
                    $display("❌ LATENCY ERROR exp=%0d got=%0d",latency_ref, latency_cnt);
                end
            end

            // done must be 1 cycle
            if (done && done_d) begin
                $display("❌ ERROR: done > 1 cycle @ %0t", $time);
                fail_count <= fail_count + 1;
            end

            // ciphertext must not change before done
            if (!rst_n && in_flight && !done && plaintext !== pt_prev) begin
                $display("❌ ERROR: ciphertext changed before done @ %0t", $time);
                fail_count <= fail_count + 1;
            end

            pt_prev <= plaintext;
        end
    end

    always@(posedge clk_100) begin
        if(done && in_flight) begin
            if(decrypted_text === plaintext) begin
                pass_count <= pass_count + 1;
                //$display("PASS | ct=%h | latency=%0d",ciphertext, latency_cnt);
                $display("S.No: %0d PASS", i);
                //$display("  Ciphertext : %h", ciphertext);
                $display("  Plaintext  : %h", decrypted_text);
                $display("  Expected   : %h", plaintext);
            end 
            if(decrypted_text !== plaintext) begin
                fail_count <= fail_count + 1;
                //$display("time : %0t | FAIL | fail_count=%0d | Expected: %h | Got: %h", $time, fail_count, expected_ciphertext, ciphertext);
                $display("S.No: %0d FAIL", i);
                //$display("  Ciphertext : %h", ciphertext);
                $display("  Expected   : %h", plaintext);
                $display("  Got     : %h", decrypted_text);
            end
        end
    end

    reg [127:0] golden_plaintext [0:9];

    initial begin
        golden_plaintext[0] = 128'h140f0f1011b5223d79587717ffd9ec3a;
        golden_plaintext[1] = 128'h00000000000000000000000000000000;
        golden_plaintext[2] = 128'h00000000000000000000000000000001;
        golden_plaintext[3] = 128'h00000000000000000000000000000002;
        golden_plaintext[4] = 128'h00000000000000000000000000000003;
        golden_plaintext[5] = 128'h00000000000000000000000000000004;
        golden_plaintext[6] = 128'h00000000000000000000000000000005;
        golden_plaintext[7] = 128'h00000000000000000000000000000006;
        golden_plaintext[8] = 128'h00000000000000000000000000000007;
        golden_plaintext[9] = 128'h00000000000000000000000000000008;
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
        start     = 1'b0;
        pass_count = 0;
        fail_count = 0;
        latency_err = 0;

        /*@(posedge clk_100);
        start = 1;
        @(posedge clk_100);
        start = 0;*/

        // Wait for system completion
        for (i = 0; i < 10; i = i + 1) begin
            aes_send_block(golden_plaintext[i], key);
            wait(done);
            plaintext = golden_plaintext[i];
            @(posedge clk_100);
        end
        //wait(done);

        // Final correctness check
        /*if (decrypted_text !== plaintext) begin
            //$fatal(1, "Time:%0t, FAIL: Decrypted text mismatch. Expected=%h Got=%h", $time, plaintext, decrypted_text);
            $display("FAIL: End-to-end AES→UART→AES verification failed at time %t", $time);
            $display("Expected=%h Got=%h, input:%h", plaintext, decrypted_text, dut.u_uart_buffer.ft_data);
            $finish;
        end else begin
            $display("PASS: End-to-end AES→UART→AES verified at time %t", $time);
            $finish;
        end*/

        // ========================================================
        // FINAL REPORT
        // ========================================================
        $display("----------------------------------");
        $display("AES DECRYPTION TEST SUMMARY");
        $display("PASS        : %0d", pass_count);
        $display("FAIL        : %0d", fail_count);
        $display("LATENCY ERR : %0d", latency_err);
        $display("LATENCY REF : %0d", latency_ref);
        $display("----------------------------------");

        if (fail_count == 0 && latency_err == 0)
            $display("✅ AES DECRYPTION TB PASSED");
        else
            $display("❌ AES DECRYPTION TB FAILED");

        $finish;

        //#1000;
        //$finish;
    end

endmodule

