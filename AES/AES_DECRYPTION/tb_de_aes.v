`timescale 1ns/1ps

module tb_de_aes;

    reg clk;
    reg rst_n;
    reg start;
    reg [127:0] ciphertext;
    reg [127:0] key;
    wire [127:0] plaintext;
    wire done;

    // -----------------------------
    // DUT
    // -----------------------------
    AES_TOP dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .ciphertext(ciphertext),
        .key(key),
        .plaintext(plaintext),
        .done(done)
    );

    // -----------------------------
    // Clock: 100 MHz
    // -----------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------
    // Test procedure
    // -----------------------------
    initial begin
        // Default values
        rst_n      = 0;
        start      = 0;
        ciphertext = 128'd0;
        key        = 128'd0;

        // Reset
        repeat (2) @(posedge clk);
        rst_n = 1;

        // Apply test vector
        ciphertext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
        key        = 128'h000102030405060708090a0b0c0d0e0f;

        // Wait one cycle for stability
        @(posedge clk);

        // Start pulse (ONE cycle only)
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for done (with timeout)
        wait_for_done;

        // Check result
        if (plaintext == 128'h00112233445566778899aabbccddeeff) begin
            $display("AES DECRYPT TEST PASSED");
        end else begin
            $display("AES DECRYPT TEST FAILED");
            $display("Got : %032h", plaintext);
            $display("Exp : 00112233445566778899aabbccddeeff");
        end

        $finish;
    end

    // -----------------------------
    // Wait-for-done task
    // -----------------------------
    task wait_for_done;
        integer cycles;
        begin
            cycles = 0;
            while (!done) begin
                @(posedge clk);
                cycles = cycles + 1;
                if (cycles > 50) begin
                    $display("TIMEOUT waiting for done");
                    $finish;
                end
            end
            $display("Done asserted after %0d cycles", cycles);
        end
    endtask

    initial begin
        #1;
        $display("CIPHERTEXT(inside testbench) = %032h", ciphertext);
        $display("KEY(inside testbench)        = %032h", key);
    end

endmodule