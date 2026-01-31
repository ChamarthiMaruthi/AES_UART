`timescale 1ns/1ps

module tb;

// =================================================================
// 1. DUT Connections and Renamed Testbench Signals
// =================================================================

// ===== Inputs to Buffer_top =====
reg         clk_3125_tx=1;
reg         clk_3125_rx=0;
reg         reset=0; // MODIFICATION: Added reset initialization here for clarity.
reg         parity_type=0;    // For TX path
reg         tx_start=0;       // For TX path
reg   [7:0] ft_data=0;           // For TX path
reg         wr_en;
// ===== Outputs from Buffer_top =====
wire        rd_en;
wire        tx;
reg         tx_exp = 1;
wire        tx_done;
wire        tx_busy;
integer     err_tx = 0;
wire        ft_full;   // MODIFICATION: Add FIFO status wire
wire        ft_empty;  // MODIFICATION: Add FIFO status wire
wire  [7:0] ft_out;
reg         rx;             // For RX path (driven by TB)
wire  [7:0] rx_msg;    // RX path output to check
reg  [7:0]   rx_exp = 0;    // Expected RX message for comparison
wire        rx_parity;
wire        rx_complete;
reg         exp_rx_complete = 0;
integer     err_rx = 0;
wire        rd_rx;
wire        wr_rx;
wire  [7:0] dout;
wire        full;
wire        empty;
// ===== TX Path Internal Signals (from uart_tx_tb) =====

integer     i_tx = 0, k_tx = 0, y_tx = 0, x_tx = 0;
integer     fd_tx = 0, fw_tx = 0;
reg [10:0]  data_packet_tx = 0;
reg [99:0]  file_data_tx = 0;
reg [(10*8)-1:0] str_tx = 0;
reg [7:0]   msg_tx = 0;
reg         flag_tx = 0;
reg         parity_bit_tx = 0;
reg         tx_done_exp = 0;
reg         flag = 0;

// ===== RX Path Internal Signals (from uart_rx_tb) =====
//integer     err_rx = 0;
integer     i_rx = 0, k_rx = 0, p_rx = 0, s_rx = 0;
integer     fd_rx = 0, fw_rx = 0;
integer     counter = 0;
reg [109:0] data_rx = 0;
reg [7:0]   msg_rx = 0;
reg [(10*11)-1:0] str_rx;
//reg [7:0]   rx_exp = 0;
reg         correct_parity = 0;
reg         flag_rx = 0;




// =================================================================
// 2. Instantiate Buffer_top (the new DUT)
// =================================================================
Buffer_top uut (
    .clk_3125_tx(clk_3125_tx),
    .clk_3125_rx(clk_3125_rx),
    .parity_type(parity_type),
    .tx_start(tx_start),
    .ft_data(ft_data),
    .tx(tx),
    .rd_en(rd_en),
    .tx_done(tx_done),
    .tx_busy(tx_busy),
    .rx(rx),
    .rx_msg(rx_msg),
    .rx_parity(rx_parity),
    .rx_complete(rx_complete),
    .ft_full(ft_full),
    .ft_empty(ft_empty),
    .ft_out(ft_out),
    .reset(reset),
    .wr_en(wr_en),
    .wr_rx(wr_rx),
    .rd_rx(rd_rx),
    .dout(dout),
    .full(full),
    .empty(empty)
);

// =================================================================
// 3. Clocks and Common Logic
// =================================================================
always begin
	clk_3125_tx = ~clk_3125_tx; #160;
end
always begin
	clk_3125_rx = ~clk_3125_rx; #160;
end

initial begin
    //reset = 0;
    //@(posedge clk_3125_tx);
    reset = 1;
    @(negedge clk_3125_tx);
    reset = 0;
end

task reverse(input [7:0] in, output [7:0] out);
  integer r;
  begin
    for(r = 0; r < 8; r = r + 1) out[r] = in[7-r];
  end
endtask


// =================================================================
// 4. TX PATH VERIFICATION LOGIC (Identical to uart_tx_tb)
// =================================================================

initial begin
    fd_tx = $fopen("data.txt","r");
    while(! $feof(fd_tx)) begin
        if($fgets(str_tx,fd_tx)) begin
            if(str_tx != 0) begin
                file_data_tx[i_tx] = str_tx[15:8] - 48;
            end
            i_tx = i_tx + 1;
        end
    end
    $fclose(fd_tx);
end

always @(msg_tx, parity_type) begin // Parity for TX checker
    case(parity_type)
        1'b0: parity_bit_tx = (^msg_tx);
        1'b1: parity_bit_tx = ~(^msg_tx);
    endcase
end

task send_data(input [7:0] msg,input parity_bit);
    begin
        data_packet_tx = {1'b1,parity_bit_tx,msg,1'b0};   // stop-parity-data-start;
        //$display("time:%0t | data_packet_tx:%b | msg:%b", $time, data_packet_tx, msg);
        for(x_tx = 0; x_tx < 11; x_tx = x_tx + 1) begin
            tx_exp = data_packet_tx[x_tx];
            repeat(13) begin
            @(posedge clk_3125_tx);
            end
            flag_tx = 1;
            @(posedge clk_3125_tx);
            flag_tx = 0;
        end
        end
endtask


initial begin
    for(y_tx = 0; y_tx < 10; y_tx = y_tx + 1) begin
        wait(reset == 0);
    	tx_start = 1;
        //$display("time:%0t | Before sending msg_tx:%b | k_tx:%0d", $time, msg_tx, k_tx);
        msg_tx = file_data_tx[(11*k_tx+1) +: 8];
        reverse(msg_tx,ft_data);
        wr_en = 1;
        @(posedge clk_3125_tx);
        wr_en = 0;
        @(posedge clk_3125_tx);
        tx_start = 0;
        send_data(msg_tx,parity_bit_tx);
        k_tx = k_tx + 1;
        //$display("time:%0t | After sending msg_tx:%b | k_tx:%0d", $time, msg_tx, k_tx);
    end
end

// =================================================================
// 5. RX PATH VERIFICATION LOGIC (Adapted from uart_rx_tb)
// =================================================================


initial begin
	fd_rx = $fopen("data.txt", "r");
	while(! $feof(fd_rx)) begin
		$fgets(str_rx, fd_rx);
		if(str_rx != 0) begin
			data_rx[i_rx] = str_rx[15:8] - 48;
		end
		i_rx = i_rx + 1;
	end
	$fclose(fd_rx);
end

initial begin
	wait(reset == 0);
	@(negedge clk_3125_rx);
	rx_exp = 0;
	repeat(156) begin @(posedge clk_3125_rx); end
	for(k_rx = 0; k_rx < 11; k_rx = k_rx+1) begin
		msg_rx = data_rx[(11*k_rx+1) + : 9];
		rx_exp = {<<{msg_rx[7:0]}};
		correct_parity = (^rx_exp)?1'b1:1'b0;
		repeat(156) begin @(posedge clk_3125_rx); end
		s_rx = s_rx + 1;
        //$display("time:%0t | s_rx:%0d | k_rx:%0d", $time, s_rx, k_rx);
	end
end

/*initial begin
	fd_rx = $fopen("data.txt", "r");
	while(! $feof(fd_rx)) begin
    if($fgets(str_rx, fd_rx)) begin
        if(str_rx != 0) begin
            rx = str_rx[15:8] - 48;
    end
	repeat(14) begin @(posedge clk_3125_rx); end
        end
        rx = 1'b0;
	end
	$fclose(fd_rx);
end*/
always @(*) begin
    rx = tx;
end

always @(posedge clk_3125_rx) begin
	exp_rx_complete = 1'b0;
    wait(reset == 0);
	if(s_rx >= (i_rx-1)/10) begin
		exp_rx_complete = 1'b0;
	end else begin
		if(counter == 156) begin
			exp_rx_complete = 1'b1;
			counter = 0;
		end
		counter <= counter + 1;
	end
end

always @(posedge exp_rx_complete) begin
  if(p_rx <= 9) begin
    p_rx <= p_rx + 1;
    if((rx_parity !== correct_parity)) begin
		  //$display("rx_msg: %c,exp_msg:%c,rx_parity:%b,correct_parity:%b",rx_msg,8'h3F,rx_parity,correct_parity);
	  end else begin
		  //$display("rx_msg: %c,exp_msg:%c,rx_parity:%b,correct_parity:%b",rx_msg,rx_exp,rx_parity,correct_parity);
	  end
  end else p_rx <= 0;
end

always @(clk_3125_rx) begin
	if(p_rx >= 10) begin
		flag_rx = 1;
	end else begin
		flag_rx = 0;
	end
end

always @(clk_3125_rx) begin
	#1;
	if (rx_parity === correct_parity) begin
		if(rx_msg !== rx_exp) begin
		 err_rx = err_rx + 1;
        end
        //$display("time:%0t | it is a parity error. | err_rx = %d", $time, err_rx);
	end
	if (rx_parity !== correct_parity) begin
		if(rx_msg !== 'h3F)
		 err_rx = err_rx + 1; 
         //$display("time:%0t | it is a parity error. | err_rx = %d", $time, err_rx);
	end
	if (rx_complete !== exp_rx_complete) begin
        err_rx = err_rx + 1'b1;
        //$display("time: %0t | rx_complete mismatch.", $time);
    end
end



always@(clk_3125_tx) begin
    if(tx !== tx_exp) err_tx = err_tx + 1;
end

// Add this declaration at the top of your tb module, along with other regs
reg tx_report_printed = 0;
reg rx_report_printed = 0; // Also add for RX for consistency, though $stop() helps there.

// Modified TX checking block
always @(posedge clk_3125_tx) begin
   // The message should only print if the condition is met AND it hasn't been printed before
   if(k_tx == i_tx/10 && !tx_report_printed) begin
        if(err_tx !== 0) begin
            fw_tx = $fopen("results.txt", "w");
            $fdisplay(fw_tx, "%02h", "Errors");
            $display("TX : Error(s) encountered, please check your design!");
            $display("Total TX Errors: %d", err_tx);
            $fclose(fw_tx);
            tx_report_printed = 1; // Set the flag so it won't print again
            // You might want to $stop() here if an error on TX should halt simulation immediately
        end else begin
            fw_tx = $fopen("results.txt", "w");
            $fdisplay(fw_tx, "%02h", "No Errors");
            $display("TX : No errors encountered, congratulations!");
            $fclose(fw_tx);
            tx_report_printed = 1; // Set the flag so it won't print again
            // If TX completion should also stop the simulation, add $stop() here.
            // However, your provided log shows RX is the one that calls $stop().
            // If both TX and RX need to complete, a single $stop() should be at a final 'done' state.
        end
   end
end

// Modified RX checking block (already has $stop(), so it prints once)
always @(clk_3125_rx) begin // Consider changing to posedge clk_3125_rx if synchronous
    // Adding the flag for consistency, though $stop() already ensures single print.
    if ((p_rx == (((i_rx-1)/10)) || (flag_rx == 1)) && !rx_report_printed) begin
        if (err_rx !== 0) begin
            fw_rx = $fopen("results.txt","w");
            $fdisplay(fw_rx, "%02h","Errors");
            repeat (125) begin @(posedge clk_3125_rx); end
            $display("RX : Error(s) encountered, please check your design!");
            $display("Total RX Errors: %d", err_rx);
            $fclose(fw_rx);
            rx_report_printed = 1; // Set flag
            $stop(); // This stops the simulation after the first print
        end
        else begin
            fw_rx = $fopen("results.txt","w");
            $fdisplay(fw_rx, "%02h","No Errors");
            repeat (125) begin @(posedge clk_3125_rx); end
            $display("RX : No errors encountered, congratulations!");
            $fclose(fw_rx);
            rx_report_printed = 1; // Set flag
            $stop(); // This stops the simulation after the first print
        end
    end
end

endmodule