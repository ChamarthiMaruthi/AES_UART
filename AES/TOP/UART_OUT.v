	// module declaration
	module uart_out(
		 input clk,
         input rst,
		 input send_start,
		 input [7:0] out,
		 output reg send, send_done, send_busy
	);

	//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

	initial begin
		 send = 1;
		 send_done = 0;
		 send_busy = 0;
	end

// --- Parameters and State Definitions ---
    localparam CLOCKS_PER_BIT = 14;
    localparam FINAL_CYCLE    = 13;
    
    localparam S_IDLE   = 4'b0000;
    localparam S_START  = 4'b0001;
    localparam S_DATA   = 4'b0010;
    localparam S_PARITY = 4'b0011;
    localparam S_STOP   = 4'b0100;
    localparam S_DONE   = 4'b0101;

    // --- Internal Registers ---
    reg [3:0]  state = S_IDLE;
    reg [3:0]  clk_counter = 0;
    // We send MSB first as per the documentation. Let the testbench do the reversing.
    reg [2:0]  bit_counter = 0;
    reg [7:0]  data_reg;
    reg        parity_bit_reg;
	 
	 
    
    //----------------------------------------------------------------------
    // SEQUENTIAL BLOCK: Handles state transitions and counters.
    // This part only changes on the clock edge.
    //----------------------------------------------------------------------
    always @(posedge clk) begin

        if (rst) begin
            state <= S_IDLE;
            clk_counter <= 0;
            bit_counter <= 0;
            send <= 1;
            send_done <= 0;
            send_busy <= 0;
        end else begin
            send_done <= 0;
            case(state)
                S_IDLE: begin
                        //$display("Time %0t : Entered S_IDLE state in UART_TX",$time);
                    clk_counter <= 0;
                    bit_counter <= 0;
                        send_busy     <= 0;
                        //rd_en       <= 1'b1;
                    if (state == S_IDLE && send_start) begin
                        send <= 1;
                            //rd_en   <= 1'b1;
                        state <= S_START;
                            $display("time:%0t | UART_TX | Moving to s_start state. rd_en asserted | out:%0h", $time, out);
                    end
                end
                
                S_START: begin
                        //$display("time:%0t, Entered start state. rd_en deasserted", $time);
                        send <= 0;
                        //rd_en <= 1'b0;
                        send_busy <= 1'b1;
                        data_reg <= out;
                        parity_bit_reg <= ^out;
                    if (clk_counter == FINAL_CYCLE) begin
                        clk_counter <= 0;
                        state <= S_DATA;
                        bit_counter <= 7; // Prepare to send MSB (data[7])
                        //$display("Time: %0t | UART_TX | State: S_START | clk_counter = %0d, bit_counter = %0d, ft_out = %0h", $time, clk_counter, bit_counter, ft_out);
                    end else begin
                        clk_counter <= clk_counter + 1;	  
                    end
                        
                end

                S_DATA: begin

                    send <= data_reg[bit_counter];
                    if (clk_counter == FINAL_CYCLE) begin
                        clk_counter <= 0;
                        if (bit_counter == 0) begin
                            state <= S_PARITY;
                        end else begin
                            bit_counter <= bit_counter - 1;
                        end
                            //$display("Time: %0t | State: S_DATA | clk_counter = %0d, bit_counter = %0d, send = %0b", $time, clk_counter, bit_counter, send);
                    end else begin
                        clk_counter <= clk_counter + 1;
                        //$display("Time: %0t | State: S_DATA | clk_counter = %0d, bit_counter = %0d, send = %0b", $time, clk_counter, bit_counter, send);
                    end
                        //$display("Time: %0t | State: S_DATA | clk_counter = %0d, bit_counter = %0d, send = %0b", $time, clk_counter, bit_counter, send);

                end
                
                S_PARITY: begin
                        //$display("time:%0t, Inside parity state of UART_TX. parity:%b", $time, parity_bit_reg);
                    send <= parity_bit_reg;
                    if (clk_counter == FINAL_CYCLE) begin
                        clk_counter <= 0;
                        state <= S_STOP;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_STOP: begin
                    send <= 1;
                    if (clk_counter == FINAL_CYCLE) begin
                        clk_counter <= 0;
                        state <= S_DONE;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                        if (clk_counter == FINAL_CYCLE - 1)begin
                            send_done <= 1;
                        end
                end

                S_DONE: begin
                    //$display("time:%0t, Transmission done in UART_TX module.", $time);
                    send <= 1;
                    state <= S_IDLE;
                    send_busy <= 0;
                        //rd_en <= 0;
                end

                default:
                    state <= S_IDLE;
            endcase
        end
    end
    

	endmodule
