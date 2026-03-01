module fifo_rx #(
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input        clk_3125_rx,
    input        reset,
    input        wr_rx,
    input        rd_rx,
    input        rx_block_ok,
    input  [7:0] din,
    output reg [7:0] dout,
    output       full,
    output       empty
);
	 integer i, k;
    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr, wr_ptr_1;
	 initial begin
		wr_ptr = 0;
		rd_ptr = 0;
		dout   = 0;
		for (i = 0; i<32; i=i+1) begin
			mem[i] = 0;
		end
	 end
     
    always @(*) begin
        wr_ptr_1 = wr_ptr - 1;
    end

    assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);
    assign empty = (wr_ptr == rd_ptr);

    wire wr_valid = wr_rx && !full;
    wire rd_valid = rd_rx && !empty;

    always @(posedge clk_3125_rx) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            dout   <= 0;
        end else begin
            if (wr_rx) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
					//$display("time:%0t, din:%0h, wr_ptr:%0d, mem:%0h", $time, din, wr_ptr, mem[wr_ptr_1[ADDR_WIDTH-1:0]]);

            end
            if (rd_rx) begin
                dout <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
					//$display("time:%0t, dout:%0h, rd_ptr:%d", $time, dout, rd_ptr);
            end
            
        end
    end
    reg rx_block_ok_d = 0;
    always @(posedge clk_3125_rx) begin
        rx_block_ok_d <= rx_block_ok;
    end

    /*always @(posedge clk_3125_rx) begin
        if (rx_block_ok_d) begin
            $display("---- FIFO_RX MEMORY DUMP ----");
            for (k = 0; k < 16; k = k + 1) begin
                $display("time:%0t mem[%0d] = %02h", $time, k, mem[k]);
            end
            $display("-----------------------------");
        end
    end*/

endmodule
