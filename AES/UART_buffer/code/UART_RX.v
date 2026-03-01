// module declaration
module uart_rx(
    input clk_3125_rx,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete, 
    output reg wr_rx,
    output reg rx_block_ok,
    output reg [4:0] byte_counter
    );

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

initial begin
    rx_msg = 0;
	rx_parity = 0;
    rx_complete = 0;
    wr_rx = 0;
    byte_counter = 0;
end

// Add your code here....

// --- Parameters and State Definitions ---
    localparam CLOCKS_PER_BIT = 14;
    localparam FINAL_CYCLE    = 13;

    // YOUR OPTIMIZED FSM: S_START is the combined IDLE/START state.
	 localparam S_IDLE   = 3'b000;
    localparam S_START  = 3'b001;
    localparam S_DATA   = 3'b010;
    localparam S_PARITY = 3'b011;
    localparam S_STOP   = 3'b100;
    
    // --- Internal Registers ---
    reg [2:0] state = S_IDLE;
    reg [4:0] clk_counter = 0;
    reg [2:0] bit_counter = 7;
    reg [7:0] data_shift_reg=0;
    //reg [4:0] byte_counter = 0; // Counts the number of bytes received in the current block
	 reg rx_start, sampled_parity;


always @(posedge clk_3125_rx) begin
rx_complete <= 0;
wr_rx <= 0;
rx_block_ok <= 0;

case(state)

				S_IDLE : begin
					 //$display("time:%0t, Inside idle state of UART_RX", $time);
					 if (rx == 0) begin
                        rx_block_ok <= 0; // Clear block complete signal when a new start bit is detected
                        wr_rx <= 0;
						state <= S_START;
                        //$display("Time: %t | UART_RX | S_IDLE  -> Detected Start Bit.", $time);
					 end
					 else begin
						state <= S_IDLE;
					 end
				end
					
            S_START: begin
						  //$display("time:%0t, Inside start state of UART_RX", $time);
                    if (clk_counter == 6) begin
                        clk_counter <= 0;
                        bit_counter <= 7; // Prepare to receive MSB first
								if(rx == 0)begin
								rx_start <= rx;
                        state <= S_DATA;
								end else begin
								clk_counter <= 0;
								state <= S_IDLE;
								end
								//$display("Time: %t | S_START -> Sampling Start Bit. Waited %d cycles. rx value: %b", $time, clk_counter + 1, rx);
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
            end
            
            S_DATA: begin
					 //$display("time:%0t, Inside data state of UART_RX", $time);
                if (clk_counter == FINAL_CYCLE) begin
                    // On the last clock tick, sample the RX line for the data bit.
						  data_shift_reg <= {data_shift_reg[6:0],rx};
                    //data_shift_reg[bit_counter] <= rx;
                    clk_counter <= 0;
						  //$display("Time: %t | S_DATA  -> Sampling data bit[%d]. Waited %d cycles. rx value: %b", $time, bit_counter, clk_counter + 1, rx);
                    if (bit_counter == 0) begin // Finished with the LSB
                        state <= S_PARITY;
                    end else begin
                        bit_counter <= bit_counter - 1;
                    end
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end

            S_PARITY: begin
                if (clk_counter == FINAL_CYCLE) begin
                    sampled_parity <= rx; // Sample the parity bit
                    clk_counter <= 0;
                    state <= S_STOP;
                    //wr_rx <= 1; // Signal to write to FIFO when parity bit is sampled
						//$display("Time: %t | S_PARITY-> Sampling Parity Bit. Waited %d cycles. rx value: %b", $time, clk_counter + 1, rx);
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end

            S_STOP : begin
					if (clk_counter == 20) begin
                        //wr_rx <= 1; // Signal to write to FIFO after stop bit is sampled
						clk_counter <= 0;
						if(rx == 1'b1) begin
							rx_msg[7:0] <= data_shift_reg[7:0];
                            wr_rx <= 1'b1;
							rx_complete <= 1'b1;
							rx_parity <= sampled_parity;
                            byte_counter <= byte_counter + 1'b1;
                            //$display("Time: %t | UART_RX | S_STOP  -> Sampling Stop Bit. Waited %d cycles. rx_msg value: %0h. FRAME COMPLETE.byte_counter: %0d", $time, clk_counter + 1, data_shift_reg, byte_counter);
                            if(byte_counter == 15) begin
                                byte_counter <= 0; // Reset byte counter after receiving a full block of 16 bytes
                                rx_block_ok <= 1'b1; // Signal that a full block has been received
                                $display("Time: %t | UART_RX | Received 16 bytes. Byte counter reset. rx_block_ok asserted. byte_counter: %0d", $time, byte_counter);
                            end
						end
						state <= S_IDLE;
                    end else begin
                        clk_counter <= clk_counter + 1;
				    end


			end

            default:
                state <= S_IDLE;
        endcase
    end

endmodule

