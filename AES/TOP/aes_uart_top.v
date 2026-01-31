module aes_uart_top (
    // ===== Clocks & Reset =====
    input  wire        clk_100,        // 100 MHz AES clock
    input  wire        clk_3125_tx,     // 3.125 MHz UART TX clock
    input  wire        clk_3125_rx,     // 3.125 MHz UART RX clock
    input  wire        rst_n,

    // ===== Control =====
    input  wire        start,           // Start full encrypt→tx→rx→decrypt flow
	 output reg         RD_RX,

    // ===== AES Inputs =====
    input  wire [127:0] plaintext,
    input  wire [127:0] key,

    // ===== AES Output =====
    output wire  [127:0] decrypted_text,
    output reg          done,

    // ===== UART Physical Loopback =====
    output wire        tx,
    input  wire        rx,
	 
	 // CDC
	 output wire enc_done,
	 output reg done_slow,
	 input  wire rst_n_slow,
	 input  wire rst_n_fast,
	 output reg  fifo_wr_en,
     output reg  fifo_wr_pulse,
     //output reg  tx_active,
     output reg  enc_done_toggle,
     output reg  tx_start_1,
     output reg storage_done
);

    // ============================================================
    // FSM States (System-level controller)
    // ============================================================
    localparam ST_IDLE        = 4'd0;
    localparam ST_ENC_START   = 4'd1;
    localparam ST_ENC_WAIT    = 4'd2;
    localparam ST_TX_BYTES    = 4'd3;
    localparam ST_TX_WAIT     = 4'd4;
    localparam ST_RX_WAIT     = 4'd5;
    localparam ST_DEC_START   = 4'd6;
    localparam ST_DEC_WAIT    = 4'd7;
    localparam ST_DONE        = 4'd8;

    reg [3:0] sys_state;

    // ============================================================
    // AES Encryption Signals
    // ============================================================
    reg         enc_start;
    //wire        enc_done;
    wire [127:0] enc_ciphertext;

    AES_TOP u_aes_encrypt (
        .clk        (clk_100),
        .rst_n      (rst_n),
        .start      (enc_start),
        .plaintext  (plaintext),
        .key        (key),
        .ciphertext (enc_ciphertext),
        .done       (enc_done)
    );

    // ============================================================
    // UART Buffer System Signals
    // ============================================================
    //reg         fifo_wr_en;
    reg  [7:0]  fifo_wr_data;
    wire        fifo_full;
    wire        fifo_empty;
    wire [7:0]  fifo_rd_data;
    wire        fifo_rd_en;

    wire [7:0]  rx_dout;
    wire        rx_empty;
	 //wire         RD_RX;
	 
	 // ============================================================
    // AES Decryption Signals
    // ============================================================
    reg         dec_start;
    wire        dec_done;
    reg  [127:0] dec_ciphertext;
	 //reg  RD_RX;

    // ============================================================
    // Byte Counters
    // ============================================================
    reg [3:0] tx_byte_cnt = 0;
    reg [3:0] rx_byte_cnt = 0;

    reg req_toggle;

    always @(posedge clk_100 or negedge rst_n_fast) begin
        if (!rst_n_fast)
            req_toggle <= 1'b0;
        else if(enc_done)
            req_toggle <= ~req_toggle;
    end

    reg [1:0] req_sync;

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow)
            req_sync <= 2'b00;
        else
            req_sync <= {req_sync[0], req_toggle};
    end

    reg req_sync_d;

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow)
            req_sync_d <= 1'b0;
        else
            req_sync_d <= req_sync[1];
    end

    //reg done_slow;

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow)
            done_slow <= 1'b0;
        else
            done_slow <= (req_sync[1] ^ req_sync_d);
    end

    reg wr_reg_toggle;

    always @(posedge clk_100 or posedge rst_n_fast) begin
        if (rst_n_fast)
            wr_reg_toggle <= 1'b0;
        else if(sys_state == ST_TX_BYTES /* && !fifo_full*/)
            wr_reg_toggle <= ~wr_reg_toggle;
    end

    reg [1:0] wr_req_sync;
    reg       wr_req_sync_d;
    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow)
            wr_req_sync <= 2'b00;
        else
            wr_req_sync <= {wr_req_sync[0], wr_reg_toggle};
            wr_req_sync_d <= wr_req_sync[1];
    end

    //wire fifo_wr_pulse = wr_req_sync[1] ^ wr_req_sync_d;

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow)
            fifo_wr_pulse <= 1'b0;
        else if (wr_req_sync[1] ^ wr_req_sync_d)
            fifo_wr_pulse <= 1'b1;
    end
    // ============================================================
    // TX Block Request / Acknowledge
    // ============================================================
    //reg enc_done_toggle;

    always @(posedge clk_100 or posedge rst_n_fast) begin
        if (rst_n_fast)
            enc_done_toggle <= 1'b0;
        else if (enc_done) begin
            enc_done_toggle <= ~enc_done_toggle;
            //if(enc_done_toggle == 1'b1)
                $display("time:%0t | enc_done_toggle toggled to %b", $time, enc_done_toggle);
        end
    end

    reg [1:0] enc_sync;
    reg       enc_sync_d;
    //wire      tx_start_1;

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow) begin
            enc_sync   <= 2'b00;
            enc_sync_d <= 1'b0;
        end else begin
            enc_sync   <= {enc_sync[0], enc_done_toggle};
            enc_sync_d <= enc_sync[1];
            //$display("time:%0t | enc_done_toggle:%b", $time, enc_done_toggle);
        end
    end

    //assign tx_start_1 = enc_sync[1] ^ enc_sync_d;   // one-cycle pulse
    //reg tx_start_1;
    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow) begin
            tx_start_1 <= 1'b0;
        end else if (enc_sync[1] ^ enc_sync_d) begin
            tx_start_1 <= 1'b1;
            $display("time:%0t | tx_start_1 is asserted", $time);
        end
        else begin
            tx_start_1 <= 1'b0;
            //$display("time:%0t | tx_start_1 is de-asserted", $time);
        end
    end

    //reg        tx_active;

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow) begin
            //tx_active   <= 1'b0;
            fifo_wr_en  <= 1'b0;
        end else begin
            //fifo_wr_en <= 1'b0;  // default

            // ---- START TX ----
            if (tx_start_1) begin
                //tx_active   <= 1'b1;
                fifo_wr_en  <= 1'b1;
                $display("time:%0t | Starting TX of encrypted data | tx_active is set to 1", $time);
            end
            else if (tx_byte_cnt == 4'd15) begin
                fifo_wr_en <= 1'b0;
                //$display("time:%0t | Completed TX of encrypted data | tx_active is set to 0", $time);
            end
        end
    end
   
    //reg storage_done = 0;
    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow) begin
            tx_byte_cnt  <= 4'd0;
            fifo_wr_data <= 8'd0;
        end else if (tx_start_1) begin
            tx_byte_cnt  <= 4'd0;
            //storage_done <= 1'b0;
        end else if (fifo_wr_en) begin
            fifo_wr_data <= enc_ciphertext[127 - tx_byte_cnt*8 -: 8];
            if(tx_byte_cnt == 4'd15) begin
                tx_byte_cnt <= 0;
                //$display("time:%0t | tx_byte_cnt is made zero after sending 16 bytes | storage_done is set to 1", $time);
                //$display("time:%0t | tx_byte_cnt is made zero after sending 16 bytes | storage_done is set to 1", $time);
            end else begin
                tx_byte_cnt  <= tx_byte_cnt + 1'b1;
            end
        end
    end

    always @(posedge clk_3125_tx or posedge rst_n_slow) begin
        if (rst_n_slow) begin
            storage_done <= 1'b0;
        end else if (fifo_wr_en == 1'b0 && !fifo_empty) begin
            storage_done <= 1'b1;
            //$display("time:%0t | storage_done is asserted", $time);
        end else begin
            storage_done <= 1'b0;
        end
    end

    Buffer_top u_uart_buffer (
        .clk_3125_tx (clk_3125_tx),
        .clk_3125_rx (clk_3125_rx),
        .reset       (!rst_n),

        // TX side
        .parity_type (1'b0),
        .tx_start    (storage_done),     // always enabled; FIFO controls flow
        .ft_data     (enc_ciphertext[127 - tx_byte_cnt*8 -: 8]),
        .wr_en       (fifo_wr_en),
        .ft_full     (fifo_full),
        .ft_empty    (fifo_empty),
        .ft_out      (),
        .rd_en       (fifo_rd_en),
        .tx          (tx),
        .tx_done     (),
        .tx_busy     (),

        // RX side
        .rx          (rx),
        .rx_msg      (),
        .rx_parity   (),
        .rx_complete (),
        .rd_rx       (RD_RX),
        .wr_rx       (),
        .dout        (rx_dout),
        .full        (),
        .empty       (rx_empty)
    );

    reg [127:0] rx_block;
    always @(posedge clk_3125_rx or negedge rst_n) begin
        if (!rst_n) begin
            RD_RX <= 1'b0;
        end else if ((!rx_empty)/* && (rx_byte_cnt < 4'd16)*/) begin
            RD_RX <= 1'b1;
            $display("time:%0t, RD_RX is asserted to read byte %0d", $time, rx_byte_cnt);
        end else begin
            RD_RX <= 1'b0;
        end
    end

    reg rx_block_ready;

    always @(posedge clk_3125_rx or negedge rst_n) begin
        if (!rst_n) begin
            rx_block_ready <= 1'b0;
        end else if (RD_RX && rx_byte_cnt == 4'd15) begin
				$display("Inside rx_block_ready assertion block at time:%0t", $time);
            rx_block_ready <= 1'b1;
        end else if (dec_start) begin
            rx_block_ready <= 1'b0;
        end
    end
	 
	 always @(posedge clk_3125_tx) begin
		if(rx_block_ready)
			$display("rx_block_ready is asserted at time:%0t", $time);
	 end

    always @(posedge clk_3125_rx or negedge rst_n) begin
        if (!rst_n) begin
            rx_byte_cnt <= 4'd0;
            rx_block    <= 128'd0;
        end else if (RD_RX) begin
            rx_block[127 - rx_byte_cnt*8 -: 8] <= rx_dout;
            rx_byte_cnt <= rx_byte_cnt + 1'b1;
        end else if (rx_block_ready) begin
            rx_byte_cnt <= 4'd0;
				$display("time:%0t, rx_byte_cnt is made zero", $time);
        end
    end

    always @(posedge clk_100 or negedge rst_n) begin
        if (!rst_n) begin
            dec_ciphertext <= 0;
        end else if (rx_block_ready) begin
            dec_ciphertext <= rx_block;
				$display("time:%0t, dec_ciphertext:%0h", $time, rx_block);
        end
    end


    ADS_TOP u_aes_decrypt (
        .clk        (clk_100),
        .rst_n      (rst_n),
        .start      (dec_start),
        .ciphertext (dec_ciphertext),
        .key        (key),
        .plaintext  (decrypted_text),
        .done       (dec_done)
    );


    // ============================================================
    // System FSM
    // ============================================================
    always @(posedge clk_100 or negedge rst_n) begin
        if (!rst_n) begin
            sys_state       <= ST_IDLE;
            enc_start       <= 0;
            dec_start       <= 0;
            done            <= 0;
        end else begin
            enc_start  <= 0;
            dec_start  <= 0;
            done       <= 0;

            case (sys_state)

                ST_IDLE: begin
                    if (start) begin
								$display("time:%0t | Entered IDLE state in top module.", $time);
                        sys_state <= ST_ENC_START;
                    end
                end

                ST_ENC_START: begin
						  $display("time:%0t | Entered start encryption state " , $time);
                    enc_start <= 1'b1;
                    sys_state <= ST_ENC_WAIT;
                end

                ST_ENC_WAIT: begin
						  
                    if (enc_done) begin
                        sys_state   <= ST_TX_BYTES;
								$display("time:%0t | Entered wait encryption state | tx_byte_cnt is made zero " , $time);
                    end
                end

                ST_TX_BYTES: begin
                    if (!fifo_full) begin
								if (tx_byte_cnt <= 4'd15) begin
                            sys_state <= ST_TX_WAIT;
									 $display("time:%0t | tx_byte_cnt:%0d | tx_block_ack received", $time, tx_byte_cnt);
                        end
                    end
                end

                ST_TX_WAIT: begin
                    if (!fifo_empty) begin
								$display("time:%0t | Next state | fifo_wr_en:%b | tx_byte_cnt:%0d", $time, fifo_wr_en, tx_byte_cnt);
                        sys_state <= ST_RX_WAIT;
                    end
                end

                ST_RX_WAIT: begin
                    if (rx_block_ready) begin
								$display("time:%0t | RX_wait state " , $time);
                        sys_state <= ST_DEC_START;
                    end
                end

                ST_DEC_START: begin
						  $display("time:%0t | Decryption start state", $time);
                    dec_start <= 1'b1;
                    sys_state <= ST_DEC_WAIT;
                end

                ST_DEC_WAIT: begin
                    if (dec_done) begin
								$display("time:%0t | Decryption done state", $time);
                        sys_state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    done      <= 1'b1;
                    sys_state <= ST_IDLE;
                end

                default: sys_state <= ST_IDLE;

            endcase
        end
    end

endmodule
