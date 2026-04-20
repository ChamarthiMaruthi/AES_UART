module aes_uart_top #( parameter loopback_test = 1)
(
    // ===== Clocks & Reset =====
    input  wire        clk_100,        // 100 MHz AES clock
    input  wire        clk_3125_tx,     // 3.125 MHz UART TX clock
    input  wire        clk_3125_rx,     // 3.125 MHz UART RX clock
    input  wire        rst,   // Synchronized reset for faster clock domain

    // ===== Control =====
    input  wire        start,           // Start full encrypt→tx→rx→decrypt flow
	 output reg         RD_RX,

    // ===== AES Inputs =====
    //input  wire [127:0] plaintext,
    //input  wire [127:0] key,

    // ===== AES Output =====
    output wire  [127:0] decrypted_text,
    output reg          done,

    // ===== UART Physical Loopback =====
    output wire        tx,
    output  wire        rx,

    // ========================================================
    input wire  in,
    output wire [7:0] input_data,
	output wire out,
	 // CDC
	 output wire enc_done,
	 output reg  fifo_wr_en,
     output reg  enc_done_toggle 
);

    // ============================================================
    // FSM States (System-level controller)
    // ============================================================
    localparam ST_IDLE        = 0;

    // Command parsing
    localparam ST_WAIT_CMD    = 1;
    localparam ST_RECV_KEY    = 2;
    localparam ST_RECV_PT     = 3;

    // Processing
    localparam ST_ENC_START   = 4;
    localparam ST_ENC_WAIT    = 5;
    localparam ST_TX_BYTES    = 6;
    localparam ST_TX_WAIT     = 7;
    localparam ST_RX_WAIT     = 8;
    localparam ST_DEC_START   = 9;
    localparam ST_DEC_WAIT    = 10;
    localparam ST_SEND_RESULT = 11;
    localparam ST_DONE        = 12;

    reg [3:0] sys_state;

    //wire [7:0] input_data;
    wire parity;
    wire in_complete;
    wire wr_in;
    wire data_valid;

    uart_in u_uart_in (
    .clk(clk_100),
    .rst(rst),
    .in(in),
    .in_msg(input_data),
    .in_parity(parity),
    .in_complete(in_complete),
    .wr_in(wr_in),
    .in_block_ok(data_valid)
    );


        // Internal registers
    reg [127:0] key_reg = 0;
    reg [127:0] plaintext_reg = 0;
    reg [3:0]   byte_idx = 0;

    // ============================================================
    // AES Encryption Signals
    // ============================================================
    reg         enc_start;
    //wire        enc_done;
    wire [127:0] enc_ciphertext;
    //reg  [127:0] key_reg;

    /*always @(posedge clk_100 or posedge rst) begin
        if (rst) begin
            key_reg <= 128'd0;
        end else begin
            key_reg <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
        end
    end*/

    AES_TOP u_aes_encrypt (
        .clk        (clk_100),
        .rst_n      (rst),
        .start      (enc_start),
        .plaintext  (plaintext_reg),
        .key        (key_reg),
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
    //reg enc_done_toggle = 0;
    //reg enc_done_toggle_1 = 0;

    always @(posedge clk_100 or posedge rst) begin
        if (rst) begin
            enc_done_toggle <= 1'b0;
            //enc_done_toggle_1 <= 1'b0;
        end else if (enc_done) begin
            enc_done_toggle <= ~enc_done_toggle;
            //enc_done_toggle_1 <= enc_done_toggle;
        end
    end

    assign enc_done_toggle_sync = enc_done_toggle;
    reg [1:0] enc_sync;
    reg       enc_sync_d;

    always @(posedge clk_3125_tx or posedge rst) begin
        if (rst) begin
            enc_sync   <= 2'b00;
            enc_sync_d <= 1'b0;
        end else begin
            enc_sync   <= {enc_sync[0], enc_done_toggle_sync};
            enc_sync_d <= enc_sync[1];
            //$display("time:%0t | enc_done_toggle:%b", $time, enc_done_toggle);
        end
    end

    reg tx_start_1 = 0;
    always @(posedge clk_3125_tx or posedge rst) begin
        if (rst) begin
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

    always @(posedge clk_3125_tx or posedge rst) begin
        if (rst) begin
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
    always @(posedge clk_3125_tx or posedge rst) begin
        if (rst) begin
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

    reg [3:0] sent_cnt;
    reg tx_start;
    always @(posedge clk_3125_tx or posedge rst) begin
    if (rst) begin
        tx_start <= 1'b0;
        sent_cnt <= 4'd0;
    end else begin
        if (tx_start_1) begin
        tx_start <= 1'b1;
        sent_cnt <= 4'd0;
        //$display("Time:%0t | tx_start is high.", $time);
        end else if (tx_start && tx_done) begin
        if (sent_cnt == 4'd15) begin
            tx_start <= 1'b0;
            //$display("Time:%0t | tx_start is low.", $time);
        end
        sent_cnt <= sent_cnt + 1'b1;
        end
    end
    end

    Buffer_top u_uart_buffer (
        .clk_3125_tx (clk_3125_tx),
        .clk_3125_rx (clk_3125_rx),
        .reset       (rst),

        // TX side
        .parity_type (1'b0),
        .tx_start    (tx_start), 
        .ft_data     (fifo_wr_data),
        .wr_en       (fifo_wr_en_hold),
        .ft_full     (fifo_full),
        .ft_empty    (fifo_empty),
        .tx          (tx),
        .tx_done     (tx_done),
        .tx_busy     (tx_busy),

        // RX side
        .rx          (rx),
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


    always @(posedge clk_3125_rx or posedge rst) begin
        if (rst) begin
            rx_block_ready <= 1'b0;
        end else if (rx_block_ok) begin
				//$display("rx_block_ready asserted at time:%0t", $time);
            rx_block_ready <= 1'b1;
        end else begin
            rx_block_ready <= 1'b0;
            //$display("time:%0t | rx_block_ready is de-asserted.", $time);
        end
    end

    
    always @(posedge clk_3125_rx or posedge rst) begin
        if (rst) begin
            RD_RX <= 1'b0;
        end else if (rx_block_ready) begin
                RD_RX <= 1'b1;
                //rd_counter <= rd_counter + 1'b1;
                //$display("time:%0t | RD_RX is asserted", $time);
        end else if (rd_counter == 5'd15) begin
                RD_RX <= 1'b0;
                rd_counter <= 5'd0;
                //$display("time: %0t | RD_RX is de-asserted", $time);
        end else if ((RD_RX == 1'b1) && (rd_counter !== 5'd15))begin
                rd_counter <= rd_counter + 1'b1; 
        end
    end

    reg dout_valid;
    always @(posedge clk_3125_rx or posedge rst) begin
        if (rst) begin
            dout_valid <= 1'b0;
        end else if (RD_RX && !empty)begin
            dout_valid <= 1'b1;
        end else begin 
            dout_valid <= 1'b0;
        end
    end

    always @(posedge clk_3125_rx or posedge rst) begin
        if (rst) begin
            rx_byte_cnt <= 4'd0;
            rx_block    <= 128'd0;
            //dec_block_ready <= 1'b0;
        end else if (dout_valid) begin
            if (rx_byte_cnt == 4'd15) begin
                rx_block[127 - rx_byte_cnt*8 -: 8] <= dout;
                rx_byte_cnt <= 0;
                //$display("time:%0t | rx_byte_cnt is made zero and dec_block_ready is asserted. dout : %0h", $time, dout);
            end else begin
                rx_block[127 - rx_byte_cnt*8 -: 8] <= dout;
                rx_byte_cnt <= rx_byte_cnt + 1'b1;
                //$display("time:%0t | rx_byte_cnt : %0d | dout : %0h", $time, rx_byte_cnt, dout);
            end
        end
    end


    always @(posedge clk_3125_rx or posedge rst) begin
        if (rst) begin
            dec_block_ready <= 1'b0;
        end else if (dout_valid && rx_byte_cnt == 4'd15) begin
            dec_block_ready <= 1'b1;
            //$display("time:%0t | dec_block_ready is asserted | rx_block : %0h", $time, rx_block[127-rx_byte_cnt*8 -:8]);
        end else begin
            dec_block_ready <= 1'b0;
            //$display("$time:%0t | dec_block_ready is de-asserted | rx_byte_cnt : %d", $time, rx_byte_cnt);
        end
    end

    always @(posedge clk_100 or posedge rst) begin
        if (rst) begin
            dec_sync <= 2'b00;
            dec_sync_d <= 1'b0;
        end else begin
            dec_sync <= {dec_sync[0], dec_block_ready};
            dec_sync_d <= dec_sync[1];
        end
    end

    wire dec_block_ready_fast = dec_sync[1] ^ dec_sync_d;

    always @(posedge clk_100 or posedge rst) begin
        if (rst) begin
            dec_ciphertext <= 0;
        end else if (dec_block_ready_fast) begin
            dec_ciphertext <= rx_block;
				//$display("time:%0t, dec_ciphertext:%0h", $time, rx_block);
        end
    end


    ADS_TOP u_aes_decrypt (
        .clk        (clk_100),
        .rst_n      (rst),
        .start      (dec_start),
        .ciphertext (dec_ciphertext),
        .key        (key_reg),
        .plaintext  (decrypted_text),
        .done       (dec_done)
    );

    // After ADS_TOP signals:
    //wire [127:0] decrypted_text;  // now internal wire, not port
    reg  [3:0]   out_byte_idx = 0;
    reg          send     = 0;
    reg          send_start = 0;
    reg  [7:0]   out_data_reg = 0;
    wire         send_busy;
    wire         send_done;

    uart_out u_uart_out (
        .clk        (clk_100),
        .rst        (rst),
        .send_start  (send_start),
        .out        (out_data_reg),
        .send       (out),
        .send_busy  (send_busy),
        .send_done  (send_done)
    );


    // ============================================================
    // System FSM
    // ============================================================
    always @(posedge clk_100 or posedge rst) begin
        if (rst) begin
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
                    if (data_valid) begin
                        //$display("time:%0t | Received first byte: %h", $time, input_data);
                        if (input_data == 8'h01) begin
                            //$display("time:%0t | Received command to start receiving key", $time);
                            sys_state <= ST_RECV_KEY;
                            byte_idx <= 0;
                        end
                        else if (input_data == 8'h02) begin
                            //$display("time:%0t | Received command to start receiving data", $time); 
                            sys_state <= ST_RECV_PT;
                            byte_idx <= 0;
                        end
                    end
                end


                ST_RECV_KEY: begin
                    if (data_valid) begin
                        //$display("time:%0t | Receiving key byte: %h", $time, input_data);
                        key_reg[127 - byte_idx*8 -: 8] <= input_data;

                        if (byte_idx == 15) begin
                            sys_state <= ST_IDLE;
                            byte_idx <= 0;
                        end else begin
                            byte_idx <= byte_idx + 1;
                        end
                    end
                end

                ST_RECV_PT: begin
                    if (data_valid) begin
                        //$display("time:%0t | Receiving plaintext byte: %h, byte_idx: %d", $time, input_data, byte_idx);
                        plaintext_reg[127 - byte_idx*8 -: 8] <= input_data;

                        if (byte_idx == 15) begin
                            byte_idx <= 0;
                            sys_state <= ST_ENC_START;
                        end else begin
                            byte_idx <= byte_idx + 1;
                        end
                    end
                end

                ST_ENC_START: begin
					//$display("time:%0t | Entered start encryption state " , $time);
                    enc_start <= 1'b1;
                    sys_state <= ST_ENC_WAIT;
                end

                ST_ENC_WAIT: begin
					enc_start <= 1'b0;	  
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
								//$display("time:%0t | RX_wait state " , $time);
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
                        sys_state <= ST_SEND_RESULT;
                        out_byte_idx <= 0;
                    end
                end

                ST_SEND_RESULT: begin
                    if (!send_busy && !send_start) begin
                        out_data_reg <= decrypted_text[127 - out_byte_idx*8 -: 8];
                        send_start     <= 1'b1;
                    end else begin
                        send_start <= 1'b0;
                        if (send_done) begin
                            if (out_byte_idx == 15) begin
                                sys_state <= ST_DONE;
                            end else begin
                                out_byte_idx <= out_byte_idx + 1;
                            end
                        end
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
