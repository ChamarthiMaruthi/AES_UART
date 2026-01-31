`timescale 1ns/1ps

module fifo_tx_tb;



// ================= FIFO_TX OF TB =================
reg reset;
reg wr_en, rd_en;
reg [7:0] din;
wire [7:0] dout;
wire full, empty;

integer fd_fifo, i_fifo, k_fifo, rd_ptr_fifo;
integer fifo_err = 0;
reg [7:0] file_data_fifo [0:31];   // enough depth for your file
reg [99:0] str_fifo;

// FIFO instance (standalone, not Buffer_top)
fifo_tx uut_fifo_tx (
    .clk   (clk_3125_tx),
    .reset (reset),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .din   (din),
    .dout  (dout),
    .full  (full),
    .empty (empty)
);

// FIFO test process
initial begin
    // reset FIFO
    reset = 1'b1;
    wr_en = 0; rd_en = 0; din = 0;
    @(posedge clk_3125_tx);
    reset = 1'b0;

    // Open file and load data
    fd_fifo = $fopen("data.txt", "r");
    if (fd_fifo == 0) begin
        $display("FIFO_TX: ERROR opening data.txt");
    end

    i_fifo = 0;
    while (! $feof(fd_fifo)) begin
        if ($fgets(str_fifo, fd_fifo)) begin
            if (str_fifo != 0) begin
                file_data_fifo[i_fifo] = str_fifo[15:8] - 48;
                i_fifo = i_fifo + 1;
            end
        end
    end
    $fclose(fd_fifo);
    $display("FIFO_TX: Loaded %0d entries from data.txt", i_fifo);

    // --- WRITE into FIFO ---
    for (k_fifo = 0; k_fifo < i_fifo; k_fifo = k_fifo + 1) begin
        while (full) @(posedge clk_3125_tx);
        din   = file_data_fifo[k_fifo];
        wr_en = 1'b1;
        @(posedge clk_3125_tx);
        wr_en = 1'b0;
        $display("FIFO_TX: wrote index %0d value 0x%0h", k_fifo, file_data_fifo[k_fifo]);
    end

    // --- READ back from FIFO ---
    rd_ptr_fifo = 0;
    for (k_fifo = 0; k_fifo < i_fifo; k_fifo = k_fifo + 1) begin
        while (empty) @(posedge clk_3125_tx);
        rd_en = 1'b1;
        @(posedge clk_3125_tx);
        rd_en = 1'b0;
        @(posedge clk_3125_tx);  // allow dout to update
        if (dout !== file_data_fifo[rd_ptr_fifo]) begin
            $display("FIFO_TX ERROR idx %0d: expected 0x%0h got 0x%0h",
                     rd_ptr_fifo, file_data_fifo[rd_ptr_fifo], dout);
            fifo_err = fifo_err + 1;
        end else begin
            $display("FIFO_TX OK    idx %0d: 0x%0h", rd_ptr_fifo, dout);
        end
        rd_ptr_fifo = rd_ptr_fifo + 1;
    end

    // Final summary
    if (fifo_err == 0)
        $display("FIFO_TX Test PASSED: no errors");
    else
        $display("FIFO_TX Test FAILED: %0d errors", fifo_err);
end
// ================= END FIFO_TX TESTBENCH BLOCK =================


endmodule

