// ===============================================================
// AES-128 Encryption Top Module (FSM-based, cycle-correct)
// One AES round per cycle
// Key expansion: combinational
// ===============================================================

module AES_TOP (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output reg  [127:0] ciphertext,
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
    reg [3:0]   round;    // 0..10

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
	 
	initial begin
		ciphertext = 0;
		done       = 0;
	 end

    //assign round_key = round_keys[round];

    always @(*) begin
        round_key <= round_keys[round];
    end

    // -----------------------------------------------------------
    // AES datapath (purely combinational)
    // -----------------------------------------------------------
    wire [127:0] sb_out;
    wire [127:0] sr_out;
    wire [127:0] mc_out;
    wire [127:0] sb_final;
    wire [127:0] sr_final;

    subBytes   u_sb (.in(state),  .out(sb_out));
    shiftRows  u_sr (.in(sb_out), .out(sr_out));
    mixColumns u_mc (.state_in(sr_out), .state_out(mc_out));

    subBytes   u_sb_final (.in(state),  .out(sb_final));
    shiftRows  u_sr_final (.in(sb_final), .out(sr_final));

    // -----------------------------------------------------------
    // FSM + sequential control
    // -----------------------------------------------------------
    always @(posedge clk or posedge rst_n) begin
        //$display("At time %t, round=%0d, start=%b state=%032h, Round key=%032h", $time, round, start, state, round_key);
        //$display("time: %t, Round key: %032h, sbout: %032h", $time, round_key, sb_out);
        //$display("time: %t, srout: %032h, mcout: %032h", $time, sr_out, mc_out);    
        if (rst_n) begin
				$display("time : %0t | Entered reset block | Encryption", $time);
            fsm_state <= S_IDLE;
            state     <= 128'd0;
            round     <= 4'd0;
            ciphertext<= 128'd0;
            done      <= 1'b0;
        end
        else begin
            done <= 1'b0;
				//ciphertext <= 128'd0;
            case (fsm_state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------
                S_IDLE: begin
						  //ciphertext <= 128'd0;
                    if (start) begin
                        //$display("time: %t, IDLE:Starting encryption | encryption | plaintext:%0h", $time, plaintext);
                        fsm_state <= S_LOAD;
                    end
                end

                // ------------------------------------------------
                // LOAD: AddRoundKey(0)
                // ------------------------------------------------
                S_LOAD: begin
                    //$display("time: %t, LOAD: AddRoundKey(0), round %0d, state=%032h, Round Key=%032h, mc_out=%032h", $time, round, state, round_key, mc_out);
                    state <= plaintext ^ round_key; // AddRoundKey(0)
                    round <= 4'd1;
                    fsm_state <= S_ROUND;
                end

                // ------------------------------------------------
                // ROUNDS 1..9
                // ------------------------------------------------
                S_ROUND: begin
                    //$display("time: %t, ROUND %0d, state=%032h, Round key=%032h, mc_out=%032h", $time, round, state, round_key, mc_out);
                    state <= mc_out ^ round_key;   // full round
                    if (round == 9) begin
                        fsm_state <= S_FINAL;
                        round <= 4'd10;
                    end
                    else begin
                        round <= round + 1'b1;
                    end
                end

                // ------------------------------------------------
                // FINAL ROUND (round 10)
                // ------------------------------------------------
                S_FINAL: begin
                    //$display("time: %t, FINAL ROUND, Round %0d, state=%032h, Round key=%032h, sr final=%032h", $time, round, state, round_key, sr_final);
                    state      <= sr_final ^ round_key; // no MixColumns
                    //ciphertext <= sr_final ^ round_key;
                    round      <= 4'd10;
                    fsm_state  <= S_DONE;
						  done       <= 1'b1;
                end

                // ------------------------------------------------
                // DONE
                // ------------------------------------------------
                S_DONE: begin
                    //$display("time: %t, Inside DONE state, ciphertext=%032h, round=%0d, done:%b", $time, state, round, done);
						  ciphertext <= state;
                    //done      <= 1'b1;
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

