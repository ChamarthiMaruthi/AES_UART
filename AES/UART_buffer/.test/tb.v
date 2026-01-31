`timescale 1ns/1ps

module tb_uart_unified;

// Clock and control signals
reg clk_3125 = 0;
reg tx_start = 0;
reg parity_type = 0;    // 0: even parity, 1: odd parity

// TX module signals
reg [7:0] tx_data = 0;
wire tx_line;
wire tx_done;

// RX module signals
wire [7:0] rx_msg;
wire rx_parity;
wire rx_complete;

// Test control variables
integer i = 0, j = 0, k = 0, err = 0;
integer fd = 0, fw = 0;
reg [(10*11)-1:0] str;
reg [7:0] test_data [0:9];  // Array to store test data
reg [7:0] expected_data [0:9];
reg expected_parity [0:9];
integer test_count = 0;
integer rx_count = 0;
reg test_complete = 0;

// Module instantiation
uart_tx tx_uut(
    .clk_3125(clk_3125),
    .parity_type(parity_type),
    .tx_start(tx_start),
    .data(tx_data),
    .tx(tx_line),
    .tx_done(tx_done)
);

uart_rx rx_uut(
    .clk_3125(clk_3125),
    .rx(tx_line),           // Connect TX output to RX input
    .rx_msg(rx_msg),
    .rx_parity(rx_parity),
    .rx_complete(rx_complete)
);

// 3.125MHz clock generation
always begin
    clk_3125 = ~clk_3125; #160;  // 160ns period = 3.125MHz
end

// Input test data - This is what we want to verify is transmitted/received correctly
initial begin
    $display("=== UART TX/RX Verification Test ===");
    $display("Purpose: Verify that data input to TX equals data output from RX");
    
    // Try to read from file first
    fd = $fopen("data.txt", "r");
    i = 0;
    if (fd) begin
        $display("Reading test data from data.txt...");
        while(!$feof(fd) && i < 10) begin
            if($fgets(str, fd)) begin
                if(str != 0) begin
                    test_data[i] = str[15:8] - 48;  // Convert ASCII to binary
                    expected_data[i] = test_data[i];  // Expected = Input (this is what we're verifying!)
                    
                    // Calculate expected parity based on the INPUT data
                    if(parity_type == 0) begin  // Even parity
                        expected_parity[i] = ^test_data[i];
                    end else begin  // Odd parity
                        expected_parity[i] = ~(^test_data[i]);
                    end
                    
                    $display("INPUT[%0d]: 0x%02h (%c) - Expected OUTPUT: 0x%02h (%c)", 
                             i, test_data[i], test_data[i], expected_data[i], expected_data[i]);
                    i = i + 1;
                end
            end
        end
        $fclose(fd);
        test_count = i;
    end else begin
        $display("File not found. Using predefined test vectors...");
        // Comprehensive test data covering different bit patterns
        test_data[0] = 8'h00;  // All zeros
        test_data[1] = 8'hFF;  // All ones  
        test_data[2] = 8'h55;  // Alternating 01010101
        test_data[3] = 8'hAA;  // Alternating 10101010
        test_data[4] = 8'h41;  // 'A' - ASCII character
        test_data[5] = 8'h7F;  // DEL character
        test_data[6] = 8'h80;  // MSB set
        test_data[7] = 8'h01;  // LSB set
        test_data[8] = 8'h3C;  // Random pattern
        test_data[9] = 8'hC3;  // Inverted pattern
        test_count = 10;
        
        for(i = 0; i < test_count; i = i + 1) begin
            expected_data[i] = test_data[i];  // What goes in MUST come out!
            
            if(parity_type == 0) begin
                expected_parity[i] = ^test_data[i];
            end else begin
                expected_parity[i] = ~(^test_data[i]);
            end
            
            $display("INPUT[%0d]: 0x%02h (binary: %08b) - Expected OUTPUT: 0x%02h", 
                     i, test_data[i], test_data[i], expected_data[i]);
        end
    end
    
    $display("Total test vectors loaded: %0d", test_count);
    $display("Parity type: %s", parity_type ? "ODD" : "EVEN");
    $display("Test principle: INPUT_DATA[i] should equal RX_OUTPUT[i]");
end

// Test sequence - send data through TX
initial begin
    // Wait for initialization
    repeat(10) @(posedge clk_3125);
    
    $display("Starting UART TX/RX test...");
    
    // Send each test data
    for(k = 0; k < test_count; k = k + 1) begin
        $display("Transmitting data[%0d] = 0x%02h (%c)", k, test_data[k], test_data[k]);
        
        // Set up data and start transmission
        tx_data = test_data[k];
        @(posedge clk_3125);
        tx_start = 1;
        @(posedge clk_3125);
        tx_start = 0;
        
        // Wait for transmission to complete
        wait(tx_done);
        $display("Transmission %0d completed", k);
        
        // Wait a bit between transmissions
        repeat(50) @(posedge clk_3125);
    end
    
    // Wait for all receptions to complete
    repeat(1000) @(posedge clk_3125);
    test_complete = 1;
    
    $display("All transmissions completed");
end

// Monitor RX completion and verify data
always @(posedge rx_complete) begin
    if(rx_count < test_count) begin
        $display("\n=== VERIFICATION for Test Vector %0d ===", rx_count);
        $display("INPUT to TX:     0x%02h (%08b) '%c'", test_data[rx_count], test_data[rx_count], 
                 (test_data[rx_count] >= 32 && test_data[rx_count] <= 126) ? test_data[rx_count] : "?");
        $display("OUTPUT from RX:  0x%02h (%08b) '%c'", rx_msg, rx_msg,
                 (rx_msg >= 32 && rx_msg <= 126) ? rx_msg : "?");
        $display("Expected parity: %b, Received parity: %b", expected_parity[rx_count], rx_parity);
        
        // The CORE verification: INPUT == OUTPUT
        if(rx_msg === test_data[rx_count]) begin
            $display("✓ DATA MATCH: TX input equals RX output");
        end else begin
            $display("✗ DATA MISMATCH: TX input ≠ RX output");
            $display("  Expected: 0x%02h, Got: 0x%02h", test_data[rx_count], rx_msg);
            $display("  Bit difference: %08b", test_data[rx_count] ^ rx_msg);
            err = err + 1;
        end
        
        // Verify parity integrity
        if(rx_parity === expected_parity[rx_count]) begin
            $display("✓ PARITY CORRECT");
        end else begin
            $display("✗ PARITY ERROR");
            $display("  Expected: %b, Got: %b", expected_parity[rx_count], rx_parity);
            err = err + 1;
        end
        
        $display("Result: %s", (rx_msg === test_data[rx_count] && rx_parity === expected_parity[rx_count]) ? "PASS" : "FAIL");
        $display("----------------------------------------");
        
        rx_count = rx_count + 1;
    end
end

// Test completion and result reporting
always @(posedge clk_3125) begin
    if(test_complete && (rx_count >= test_count)) begin
        repeat(100) @(posedge clk_3125);  // Wait a bit more
        
        $display("=== Test Summary ===");
        $display("Total tests: %0d", test_count);
        $display("Tests passed: %0d", test_count - err);
        $display("Errors: %0d", err);
        
        // Write results to file
        fw = $fopen("results.txt", "w");
        if(err == 0) begin
            $fdisplay(fw, "No Errors");
            $display("✓ All tests PASSED! No errors encountered.");
        end else begin
            $fdisplay(fw, "Errors");
            $display("✗ %0d error(s) encountered. Please check your design!", err);
        end
        $fclose(fw);
        
        $finish();
    end
end

// Timeout mechanism
initial begin
    #50000000;  // 50ms timeout
    $display("ERROR: Test timeout!");
    $finish();
end

// Optional: Monitor TX line for debugging
always @(tx_line) begin
    $display("TX line changed to: %b at time %0t", tx_line, $time);
end

endmodule
