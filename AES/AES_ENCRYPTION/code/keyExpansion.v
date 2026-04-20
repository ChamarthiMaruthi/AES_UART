module keyExpansion (
    input  wire         clk,
    input  wire         rst_n,       // active LOW
    input  wire         start,

    input  wire [127:0] key_in,

    output reg  [127:0] round_key,
    output reg  [3:0]   round,
    output reg          valid
);

    // ------------------------------------------------------------
    // Internal registers
    // ------------------------------------------------------------
    reg [127:0] key_reg;
    reg [1407:0] fullkeys; // 11 round keys * 128 bits each = 1408 bits
    reg running;

    // Split into words
    wire [31:0] w0 = key_reg[127:96];
    wire [31:0] w1 = key_reg[95:64];
    wire [31:0] w2 = key_reg[63:32];
    wire [31:0] w3 = key_reg[31:0];

    // ------------------------------------------------------------
    // RotWord
    // ------------------------------------------------------------
    wire [31:0] rot_w3 = {w3[23:0], w3[31:24]};

    // ------------------------------------------------------------
    // SubWord using S-box module (4 instances)
    // ------------------------------------------------------------
    wire [7:0] s0, s1, s2, s3;

    sbox u0 (.a(rot_w3[31:24]), .sbout(s0));
    sbox u1 (.a(rot_w3[23:16]), .sbout(s1));
    sbox u2 (.a(rot_w3[15:8]),  .sbout(s2));
    sbox u3 (.a(rot_w3[7:0]),   .sbout(s3));

    wire [31:0] subword = {s0, s1, s2, s3};

    // ------------------------------------------------------------
    // Rcon
    // ------------------------------------------------------------
    function [31:0] rcon;
        input [3:0] r;
        begin
            case (r)
                4'd1:  rcon = 32'h01000000;
                4'd2:  rcon = 32'h02000000;
                4'd3:  rcon = 32'h04000000;
                4'd4:  rcon = 32'h08000000;
                4'd5:  rcon = 32'h10000000;
                4'd6:  rcon = 32'h20000000;
                4'd7:  rcon = 32'h40000000;
                4'd8:  rcon = 32'h80000000;
                4'd9:  rcon = 32'h1b000000;
                4'd10: rcon = 32'h36000000;
                default: rcon = 32'h00000000;
            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // Next key computation (combinational for ONE round)
    // ------------------------------------------------------------
    wire [31:0] temp = subword ^ rcon(round);

    wire [31:0] new_w0 = w0 ^ temp;
    wire [31:0] new_w1 = w1 ^ new_w0;
    wire [31:0] new_w2 = w2 ^ new_w1;
    wire [31:0] new_w3 = w3 ^ new_w2;

    wire [127:0] next_key = {new_w0, new_w1, new_w2, new_w3};

    // ------------------------------------------------------------
    // Sequential control
    // ------------------------------------------------------------
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            key_reg   <= 0;
            fullkeys  <= 0;
            round     <= 0;
            running   <= 0;
            valid     <= 0;
            round_key <= 0;
        end
        else begin
            valid <= 0;

            // Start condition
            if (start && !running) begin
                key_reg <= key_in;
                fullkeys[128*0 +: 128]   <= key_in;
                round     <= 1;
                running   <= 1;

                round_key <= key_in;  // round 0 key
                valid     <= 1;
            end

            // Generate next keys
            else if (running) begin
                key_reg <= next_key;
                fullkeys[128*round +: 128]   <= next_key;
                round_key <= next_key;
                valid     <= 1;

                if (round == 10) begin
                    running <= 0;
                    round   <= 0;
                end
                else begin
                    round <= round + 1;
                end
            end
        end
    end

endmodule