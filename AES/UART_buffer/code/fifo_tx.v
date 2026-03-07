module fifo_tx #(
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter TX_THRESHOLD = 0 // Auto-start when atleast 1 byte is available  
)(
    input              clk_3125_tx,  // Clock
    input              reset,        // Synchronous reset
    input              wr_en,        // Write enable
    input              rd_en,        // Read enable
    input      [7:0]   ft_data,      // Data input
    output             ft_full,      // FIFO full status
    output             ft_empty,     // FIFO empty status
    output reg [7:0]   ft_out,        // Data output (registered)
    output             ft_ready      // Ready signal for UART
);

    // --- Internal Storage ---
    (* ramstyle = "M9K" *) reg [7:0] mem [0:DEPTH-1];

    // --- Pointers (with extra bit for full/empty detection) ---
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH-1:0] wr_addr_reg;
    reg [ADDR_WIDTH-1:0] rd_addr_reg;
    //wire [ADDR_WIDTH-1:0] data_count = wr_ptr - rd_ptr; // Number of items in FIFO

    initial begin
		wr_ptr     = 0;
        rd_ptr     = 0;
    end

	 // --- Status Logic ---
    assign ft_empty = (wr_ptr == rd_ptr);
    assign ft_full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]);
    assign ft_ready = (wr_ptr >= TX_THRESHOLD); // FIFO is ready to accept data when not full

	 
	 /*always@(posedge clk_3125_tx) begin
		if(ft_empty) begin
			$display("time: %0t | FIFO_TX is empty.| rd_ptr:%d | wr_ptr:%d | wr_en:%b", $time, rd_ptr, wr_ptr, wr_en);
		end
		if(ft_full) begin
			$display("time: %0t | FIFO_TX is full.| rd_ptr:%d | wr_ptr:%d | wr_en:%b", $time, rd_ptr, wr_ptr, wr_en);
		end
	 end*/
	 
    // --- FIFO Logic ---
    always @(posedge clk_3125_tx) begin
        if (reset) begin
            wr_ptr     <= 0;
            rd_ptr     <= 0;
            ft_out     <= 0;
            wr_addr_reg <= 0;
            rd_addr_reg <= 0;
        end else begin
				//$display("time:%0t, Inside FIFO_TX.wr_en:%b.ft_full:%b", $time, wr_en, ft_full);
            // -----------------------
            // Write Operation
            // -----------------------
            if (wr_en && !ft_full) begin
					//$display("time:%0t | ft_data : %0h | rd_ptr:%d | wr_ptr:%d | wr_en:%b",$time,ft_data,rd_ptr,wr_ptr, wr_en);
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= ft_data;
                wr_addr_reg <= wr_ptr[ADDR_WIDTH:0];
                wr_ptr <= wr_ptr + 1;
            end

            // -----------------------
            // FWFT Read Operation
            // -----------------------
            if (rd_en && !ft_empty) begin
                    //$display("time:%0t | FIFO_TX Read | rd_ptr:%d | ft_out:%0h | ft_ready:%b", $time, rd_ptr, ft_out, ft_ready);
                    //ft_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                    rd_addr_reg <= rd_ptr[ADDR_WIDTH-1:0];
                    rd_ptr <= rd_ptr + 1;
            end

            ft_out <= mem[rd_addr_reg];
            //mem[wr_addr_reg] <= ft_data;
        end
    end

endmodule
