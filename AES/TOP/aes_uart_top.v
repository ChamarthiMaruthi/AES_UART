module aes_uart_top #( parameter loopback_test = 0)
(
    // ===== Clocks & Reset =====
    input  wire        clk_100,        // 100 MHz AES clock
    input  wire        clk_3125_tx,     // 3.125 MHz UART TX clock
    input  wire        clk_3125_rx,     // 3.125 MHz UART RX clock
    input  wire        rst_n,   // Synchronized reset for faster clock domain

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
	 output reg  fifo_wr_en
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
    //wire        tx_start;
    wire [7:0]  ft_data;
    wire        fifo_full;
    wire        fifo_empty;
    wire [7:0]  ft_out;
    wire        rd_en;
    reg  [7:0]  fifo_wr_data;
    wire [7:0]  fifo_rd_data;
    wire        fifo_rd_en;
    wire [7:0]  dout;
    wire [7:0]  rx_msg;
    wire [3:0]  byte_counter;
    wire        rx_parity;
    wire        rx_empty;
    wire        rx_complete;
    wire        full;
    wire        empty;
    wire        tx_done;
    wire        tx_busy;
    wire        rx_block_ok;
    wire        wr_rx; // Write to FIFO when RX is complete and FIFO is not full
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

    // ============================================================
    // TX Block Request / Acknowledge
    // ============================================================
    reg enc_done_toggle = 0;

    always @(posedge clk_100 or posedge rst_n) begin
        if (rst_n)
            enc_done_toggle <= 1'b0;
        else if (enc_done) begin
            enc_done_toggle <= ~enc_done_toggle;
        end
    end

    reg [1:0] enc_sync;
    reg       enc_sync_d;

    always @(posedge clk_3125_tx or posedge rst_n) begin
        if (rst_n) begin
            enc_sync   <= 2'b00;
            enc_sync_d <= 1'b0;
        end else begin
            enc_sync   <= {enc_sync[0], enc_done_toggle};
            enc_sync_d <= enc_sync[1];
            //$display("time:%0t | enc_done_toggle:%b", $time, enc_done_toggle);
        end
    end

    reg tx_start_1 = 0;
    always @(posedge clk_3125_tx or posedge rst_n) begin
        if (rst_n) begin
            tx_start_1 <= 1'b0;
        end else if (enc_sync[1] ^ enc_sync_d) begin
            tx_start_1 <= 1'b1;
            //$display("time:%0t | tx_start_1 is asserted", $time);
        end
        else begin
            tx_start_1 <= 1'b0;
            //$display("time:%0t | tx_start_1 is de-asserted", $time);
        end
    end

    always @(posedge clk_3125_tx or posedge rst_n) begin
        if (rst_n) begin
            fifo_wr_en  <= 1'b0;
        end else  begin
            if (tx_byte_cnt == 4'd15) begin
                fifo_wr_en <= 1'b0;
                //$display("time:%0t | All bytes written to FIFO, fifo_wr_en is de-asserted", $time);
            end else if (tx_start_1) begin
                fifo_wr_en <= 1'b1;
                //$display("time:%0t | fifo_wr_en is asserted", $time);
            end
        end
    end
   
    reg fifo_wr_en_hold;
    always @(posedge clk_3125_tx or posedge rst_n) begin
        if (rst_n) begin
            tx_byte_cnt  <= 4'd0;
            fifo_wr_data <= 8'd0;
            fifo_wr_en_hold <= 1'b0;
        end else if (fifo_wr_en) begin
            fifo_wr_en_hold <= 1'b1;
            fifo_wr_data <= enc_ciphertext[127 - tx_byte_cnt*8 -: 8];
            //$display("time:%0t | Writing byte %0d to FIFO: %h", $time, tx_byte_cnt, fifo_wr_data);
            tx_byte_cnt  <= tx_byte_cnt + 1'b1;
        end
        else if (fifo_wr_en == 1'b0) begin
            fifo_wr_en_hold <= 1'b0;
            tx_byte_cnt <= 4'd0;
        end
    end

    Buffer_top u_uart_buffer (
        .clk_3125_tx (clk_3125_tx),
        .clk_3125_rx (clk_3125_rx),
        .reset       (rst_n),

        // TX side
        .parity_type (1'b0),
        //.tx_start    (tx_start), 
        .ft_data     (fifo_wr_data),
        .wr_en       (fifo_wr_en_hold),
        .ft_full     (fifo_full),
        .ft_empty    (fifo_empty),
        .tx          (tx),
        .tx_done     (tx_done),
        .tx_busy     (tx_busy),

        // RX side
        .rx          (loopback_test ? tx : rx),
        .rx_msg      (rx_msg),
        .rx_block_ok (rx_block_ok),
        .rx_complete (rx_complete), 
        .rd_rx       (RD_RX),
        .wr_rx       (wr_rx),
        .dout        (dout),
        .full        (full),
        .empty       (empty)
    );


    reg [127:0] rx_block;
    reg rx_block_ready = 0;
    reg dec_block_ready = 0;
    reg [4:0] rd_counter = 0;
    reg dec_sync_d = 0;
    reg [1:0] dec_sync = 0;


    always @(posedge clk_3125_rx or posedge rst_n) begin
        if (rst_n) begin
            rx_block_ready <= 1'b0;
        end else if (rx_block_ok) begin
				//$display("rx_block_ready asserted at time:%0t", $time);
            rx_block_ready <= 1'b1;
        end else begin
            rx_block_ready <= 1'b0;
            //$display("time:%0t | rx_block_ready is de-asserted.", $time);
        end
    end

    
    always @(posedge clk_3125_rx or posedge rst_n) begin
        if (rst_n) begin
            RD_RX <= 1'b0;
        end else if (rx_block_ready) begin
                RD_RX <= 1'b1;
                rd_counter <= rd_counter + 1'b1;
                $display("time:%0t | RD_RX is asserted", $time);
        end else if (rd_counter == 5'd16) begin
                RD_RX <= 1'b0;
                rd_counter <= 5'd0;
                //$display("time: %0t | RD_RX is de-asserted", $time);
        end else if ((RD_RX == 1'b1) && (rd_counter !== 5'd16))begin
                rd_counter <= rd_counter + 1'b1; 
        end
    end

    reg rd_rx_1;
    always @(posedge clk_3125_rx or posedge rst_n) begin
        if (rst_n) begin
            rd_rx_1 <= 1'b0;
        end else begin
            rd_rx_1 <= RD_RX;
        end
    end

    always @(posedge clk_3125_rx or posedge rst_n) begin
        if (rst_n) begin
            rx_byte_cnt <= 4'd0;
            rx_block    <= 128'd0;
            //dec_block_ready <= 1'b0;
        end else if (rd_rx_1) begin
            if (rx_byte_cnt == 4'd15) begin
                rx_block[127 - rx_byte_cnt*8 -: 8] <= dout;
                rx_byte_cnt <= 0;
                $display("time:%0t | rx_byte_cnt is made zero and dec_block_ready is asserted. dout : %0h", $time, dout);
            end else begin
                rx_block[127 - rx_byte_cnt*8 -: 8] <= dout;
                rx_byte_cnt <= rx_byte_cnt + 1'b1;
                $display("time:%0t | rx_byte_cnt : %0d | dout : %0h", $time, rx_byte_cnt, dout);
            end
        end
    end


    always @(posedge clk_3125_rx or posedge rst_n) begin
        if (rst_n) begin
            dec_block_ready <= 1'b0;
        end else if (rd_rx_1 && rx_byte_cnt == 4'd15) begin
            dec_block_ready <= 1'b1;
            $display("time:%0t | dec_block_ready is asserted | rx_block : %0h", $time, rx_block[127-rx_byte_cnt*8 -:8]);
        end else begin
            dec_block_ready <= 1'b0;
            //$display("$time:%0t | dec_block_ready is de-asserted | rx_byte_cnt : %d", $time, rx_byte_cnt);
        end
    end

    always @(posedge clk_100 or posedge rst_n) begin
        if (rst_n) begin
            dec_sync <= 2'b00;
            dec_sync_d <= 1'b0;
        end else begin
            dec_sync <= {dec_sync[0], dec_block_ready};
            dec_sync_d <= dec_sync[1];
        end
    end

    wire dec_block_ready_fast = dec_sync[1] ^ dec_sync_d;

    always @(posedge clk_100 or posedge rst_n) begin
        if (rst_n) begin
            dec_ciphertext <= 0;
        end else if (dec_block_ready_fast) begin
            dec_ciphertext <= rx_block;
				//$display("time:%0t, dec_ciphertext:%0h", $time, rx_block);
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
    always @(posedge clk_100 or posedge rst_n) begin
        if (rst_n) begin
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
								//$display("time:%0t | Entered IDLE state in top module.", $time);
                        sys_state <= ST_ENC_START;
                    end
                end

                ST_ENC_START: begin
						  //$display("time:%0t | Entered start encryption state " , $time);
                    enc_start <= 1'b1;
                    sys_state <= ST_ENC_WAIT;
                end

                ST_ENC_WAIT: begin
						  
                    if (enc_done) begin
                        sys_state   <= ST_TX_BYTES;
								//$display("time:%0t | Entered wait encryption state | tx_byte_cnt is made zero " , $time);
                    end
                end

                ST_TX_BYTES: begin
                    if (!fifo_full) begin
								if (tx_byte_cnt == 4'd15) begin
                            sys_state <= ST_TX_WAIT;
									 //$display("time:%0t | tx_byte_cnt:%0d | tx_block_ack received", $time, tx_byte_cnt);
                        end
                    end
                end

                ST_TX_WAIT: begin
                    if (tx_done) begin
								//$display("time:%0t | Next state | fifo_wr_en:%b | tx_byte_cnt:%0d", $time, fifo_wr_en, tx_byte_cnt);
                        sys_state <= ST_RX_WAIT;
                    end
                end

                ST_RX_WAIT: begin
                    if (dec_block_ready_fast) begin
								$display("time:%0t | RX_wait state " , $time);
                        sys_state <= ST_DEC_START;
                    end
                end

                ST_DEC_START: begin
						  //$display("time:%0t | Decryption start state", $time);
                    dec_start <= 1'b1;
                    sys_state <= ST_DEC_WAIT;
                end

                ST_DEC_WAIT: begin
                    if (dec_done) begin
								//$display("time:%0t | Decryption done state", $time);
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
