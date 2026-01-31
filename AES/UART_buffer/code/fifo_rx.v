module fifo_rx #(
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input        clk_3125_rx,
    input        reset,
    input        wr_rx,
    input        rd_rx,
    input  [7:0] din,
    output reg [7:0] dout,
    output       full,
    output       empty
);
	 integer i;
    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
	 initial begin
		wr_ptr = 0;
		rd_ptr = 0;
		dout   = 0;
		for (i = 0; i<32; i=i+1) begin
			mem[i] = 0;
		end
	 end

    assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
                   (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);
    assign empty = (wr_ptr == rd_ptr);

    wire wr_valid = wr_rx && !full;
    wire rd_valid = rd_rx && !empty;

    always @(posedge clk_3125_rx) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            dout   <= 0;
        end else begin
            if (wr_valid) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
					 //$strobe("time:%0t, din:%0h, wr_ptr:%d, mem:%0h", $time, din, wr_ptr, mem[wr_ptr[ADDR_WIDTH-1:0]]);
            end
            if (rd_valid) begin
                dout <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
					 //$display("time:%0t, dout:%0h, rd_ptr:%d", $time, dout, rd_ptr);
            end
        end
    end
endmodule
