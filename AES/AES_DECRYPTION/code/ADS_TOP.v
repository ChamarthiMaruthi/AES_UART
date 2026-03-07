// ===============================================================
// AES-128 Decryption Top Module (FSM-based, cycle-correct)
// One AES inverse round per cycle
// Key expansion: combinational
// ===============================================================

module ADS_TOP (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] ciphertext,
    input  wire [127:0] key,
    output reg  [127:0] plaintext,
    output reg          done
);

    // -----------------------------------------------------------
    // FSM state encoding
    // -----------------------------------------------------------
    localparam S_IDLE  = 3'd0;
    localparam S_LOAD  = 3'd1;
    localparam S_ROUND = 3'd2;
    localparam S_FINAL = 3'd3;
    localparam S_DONE  = 3'd4;

    reg [2:0] fsm_state;

    // -----------------------------------------------------------
    // AES state and round counter
    // -----------------------------------------------------------
    reg [127:0] state;
    reg [3:0]   round;    // 10..0
	 
	 initial begin
		state <= 0;
		round <= 0;
	 end

    // -----------------------------------------------------------
    // Key expansion (combinational)
    // -----------------------------------------------------------
    wire [1407:0] round_keys_comb;
    reg [127:0]  round_key;
    reg  [127:0]  round_keys[0:10];

    keyExpansion keyexp (
        .key      (key),
        .fullkeys (round_keys_comb)
    );


    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            round_keys[0]  <= 0;
            round_keys[1]  <= 0;
            round_keys[2]  <= 0;
            round_keys[3]  <= 0;
            round_keys[4]  <= 0;
            round_keys[5]  <= 0;
            round_keys[6]  <= 0;
            round_keys[7]  <= 0;
            round_keys[8]  <= 0;
            round_keys[9]  <= 0;
            round_keys[10] <= 0;
        end
        else if (start) begin
            round_keys[0]  <= round_keys_comb[127:0];
            round_keys[1]  <= round_keys_comb[255:128];
            round_keys[2]  <= round_keys_comb[383:256];
            round_keys[3]  <= round_keys_comb[511:384];
            round_keys[4]  <= round_keys_comb[639:512];
            round_keys[5]  <= round_keys_comb[767:640];
            round_keys[6]  <= round_keys_comb[895:768];
            round_keys[7]  <= round_keys_comb[1023:896];
            round_keys[8]  <= round_keys_comb[1151:1024];
            round_keys[9]  <= round_keys_comb[1279:1152];
            round_keys[10] <= round_keys_comb[1407:1280];
        end
    end
	 
    always @(*) begin
        round_key <= round_keys[round];
    end
    //assign round_key = round_keys[round*128 +: 128];


    // -----------------------------------------------------------
    // AES inverse datapath (purely combinational)
    // -----------------------------------------------------------
    wire [127:0] round_out;
    wire [127:0] final_out;
    wire [127:0] isr_out;
    wire [127:0] isb_out;
    wire [127:0] imc_in;
    wire [127:0] imc_out;

    /*decryptRound u_dec_round (
        .state_in (state),
        .round_key(round_key),
        .state_out(round_out)
    );

    finalInvRound u_dec_final (
        .state_in (state),
        .round_key(round_keys[0 +: 128]),
        .state_out(final_out)
    );*/

    inverseShiftRows u_isr (
        .in(state),
        .out(isr_out)
    );
    inverseSubBytes u_isb (
        .in(isr_out),
        .out(isb_out)
    );

    assign imc_in = isb_out ^ round_key ;
    invMixColumns u_imc (
        .state_in(imc_in),
        .state_out(imc_out)
    );

    // -----------------------------------------------------------
    // FSM + sequential control
    // -----------------------------------------------------------
    always @(posedge clk or posedge rst_n) begin
        //$display("At time %t, round=%0d, start=%b state=%032h, Round key=%032h", $time, round, start, state, round_key);
        //$display("time: %t, Round key: %032h, sbout: %032h", $time, round_key, sb_out);
        //$display("time: %t, srout: %032h, mcout: %032h", $time, sr_out, mc_out);    
        if (rst_n) begin
				$display("time:%0t, Entered reset block | Decryption | state=%032h", $time, state);
            fsm_state <= S_IDLE;
            state     <= 128'd0;
            round     <= 4'd0;
            plaintext <= 128'd0;
            done      <= 1'b0;
            //round_key <= 128'd0;
        end
        else begin
            done <= 1'b0;

            case (fsm_state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------
                S_IDLE: begin
                    if (start) begin
                        //$display("time: %t, IDLE:Starting decryption, ciphertext=%032h, key=%032h,", $time, ciphertext, key);
                        round     <= 4'd10;
                        fsm_state <= S_LOAD;
                    end
                end

                // ------------------------------------------------
                // LOAD: initial AddRoundKey (round 10)
                // ------------------------------------------------
                S_LOAD: begin
                    //$display("time: %t, LOAD: AddRoundKey(10), state=%032h,round_key : %032h", $time, state, round_key);
                    state <= ciphertext ^ round_key;
                    //round <= 4'd9;
                    round <= round - 1'b1;
                    fsm_state <= S_ROUND;
                end

                // ------------------------------------------------
                // ROUNDS 9..1
                // ------------------------------------------------
                S_ROUND: begin
                    //$display("time: %t, INV ROUND %0d, state=%032h, round_key : %032h", $time, round, state, round_key);
                    state <= imc_out; 
                    if (round == 4'd1) begin
                        fsm_state <= S_FINAL;
                        round <= 4'd0;
                    end else begin
                        round <= round - 1'b1;
                    end
                end

                // ------------------------------------------------
                // FINAL ROUND (round 0)
                // ------------------------------------------------
                S_FINAL: begin
                    //$display("time: %t, FINAL INV ROUND, state=%032h, isb_out=%032h, round_kkey : %032h", $time, state, isr_out, round_key);
                    state     <= imc_in;
                    plaintext <= imc_in;
                    round     <= 4'd0;
                    fsm_state  <= S_DONE;
						  done       <= 1'b1;
                end

                // ------------------------------------------------
                // DONE
                // ------------------------------------------------
                S_DONE: begin
                    //$display("time: %t, DONE, plaintext=%032h, imc_in=%032h, round_key=%032h", $time, state, imc_in, round_key);
                    //done      <= 1'b1;
						  //plaintext <= state;
                    fsm_state<= S_IDLE;
                    round    <= 4'd0;
                end

                default: begin
                    fsm_state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
