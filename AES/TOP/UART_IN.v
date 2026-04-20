// module declaration
module uart_in(
    input clk,
    input in,
    output reg [7:0] in_msg,
    output reg in_parity,
    output reg in_complete, 
    output reg wr_in,
    output reg in_block_ok
    //output reg [4:0] byte_counter
    );

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

initial begin
    in_msg = 0;
	in_parity = 0;
    in_complete = 0;
    wr_in = 0;
    //byte_counter = 0;
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
    reg [4:0] byte_counter = 0; // Counts the number of bytes received in the current block
	reg in_start, sampled_parity;
    reg computed_parity = 0; // Register to hold the computed parity
    //wire computed_parity = ^data_shift_reg; // Compute parity bit (even parity) on the fly
    reg parity_err = 0; // Register to hold parity error status

reg in_s1, in_s2;

always @(posedge clk) begin
    in_s1 <= in;
    in_s2 <= in_s1;
end

always @(posedge clk) begin
in_complete <= 0;
wr_in <= 0;
in_block_ok <= 0;

case(state)

				S_IDLE : begin
					 //$display("time:%0t, Inside idle state of UART_in", $time);
                     parity_err <= 0; // Clear parity error at the start of a new reception
					 if (in_s2 == 0) begin
                        in_block_ok <= 0; // Clear block complete signal when a new start bit is detected
                        wr_in <= 0;
						state <= S_START;
                        $display("Time: %t | UART_in | S_IDLE  -> Detected Start Bit.", $time);
					 end
					 else begin
						state <= S_IDLE;
                        //$display("Time: %t | UART_in | S_IDLE  -> Waiting for Start Bit. in value: %b", $time, in_s2);
					 end
				end
					
            S_START: begin
						  //$display("time:%0t, Inside start state of UART_in", $time);
                    if (clk_counter == 6) begin
                        //clk_counter <= 0;
                        //bit_counter <= 7; // Prepare to receive MSB first
						if(in_s2 == 0)begin
							in_start <= in_s2; // Sample the start bit at the middle of the bit period
                            clk_counter <= clk_counter + 1; // Move to the next cycle to sample the first data bit
                            //state <= S_DATA;
						end else begin
							clk_counter <= 0;
							state <= S_IDLE;
						end
								//$display("Time: %t | S_START -> Sampling Start Bit. Waited %d cycles.  value: %b", $time, clk_counter + 1, in);
                    end else if (clk_counter == FINAL_CYCLE) begin
                        state <= S_DATA;
                        clk_counter <= 0;
                        bit_counter <= 7; // Prepare to receive MSB first
                        //$display("Time: %t | S_START -> Start Bit Validated. Moving to S_DATA. in value: %b", $time, in_s2);
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
            end
            
            S_DATA: begin
                if (clk_counter == 6) begin
                    // On the last clock tick, sample the input line for the data bit.
						  data_shift_reg <= {data_shift_reg[6:0],in_s2};
                          clk_counter <= clk_counter + 1;
                    //data_shift_reg[bit_counter] <= in;
                end else if (clk_counter == FINAL_CYCLE) begin
                    clk_counter <= 0;
						  //$display("Time: %t | S_DATA  -> Sampling data bit[%d]. Waited %d cycles. in value: %b", $time, bit_counter, clk_counter + 1, in_s2);
                    if (bit_counter == 0) begin // Finished with the LSB
                        computed_parity <= ^data_shift_reg; // Compute parity bit (even parity)
                        $display("Time: %t | S_DATA -> Received byte: %0h. Computed parity: %b", $time, data_shift_reg, computed_parity);
                        state <= S_PARITY;
                    end else begin
                        bit_counter <= bit_counter - 1;
                    end
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end

            S_PARITY: begin
                if (clk_counter == 6) begin
                    sampled_parity <= in_s2; // Sample the parity bit
                    clk_counter <= clk_counter + 1;
                end else if (clk_counter == 7) begin
                    // Check parity error
                    if (sampled_parity !== computed_parity) begin
                        parity_err <= 1'b1;
                    end else begin
                        parity_err <= 1'b0;
                    end
                    clk_counter <= clk_counter + 1; // Move to the next cycle to sample the stop bit
                end else if (clk_counter == FINAL_CYCLE) begin
                    clk_counter <= 0;
                    state <= S_STOP;
					$display("Time: %t | S_PARITY-> Sampling Parity Bit. Waited %d cycles. in value: %b, byte_counter: %d, computed_parity: %b, sampled_parity: %b, parity_err: %b", $time, clk_counter + 1, in_s2, byte_counter, computed_parity, sampled_parity, parity_err);
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end

            S_STOP : begin
					if (clk_counter == FINAL_CYCLE) begin
                        //wr_in <= 1; // Signal to write to FIFO after stop bit is sampled
						clk_counter <= 0;
						if(in_s2 == 1'b1 && (parity_err == 1'b0)) begin
							in_msg[7:0] <= data_shift_reg[7:0];
                            in_block_ok <= 1'b1; // Signal that a full block has been received
                            wr_in <= 1'b1;
							in_complete <= 1'b1;
							in_parity <= sampled_parity;
                            byte_counter <= byte_counter + 1'b1;
                            //$display("Time: %t | UART_in | S_STOP  -> Sampling Stop Bit. Waited %d cycles. in_msg value: %0h. FRAME COMPLETE.byte_counter: %0d", $time, clk_counter + 1, data_shift_reg, byte_counter);
                            if(byte_counter == 15) begin
                                byte_counter <= 0; // Reset byte counter after receiving a full block of 16 bytes
                                //in_block_ok <= 1'b1; // Signal that a full block has been received
                                //$display("Time: %t | UART_in | Received 16 bytes. Byte counter reset. in_block_ok asserted. byte_counter: %0d", $time, byte_counter);
                            end
                        end
                        if (in_s2 == 0) begin
                            state <= S_START;
                            clk_counter <= 1;
                            bit_counter <= 7;
                            parity_err  <= 0;
                        end else begin
						    state <= S_IDLE;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
				    end


			end

            default:
                state <= S_IDLE;
        endcase
    end

endmodule

