module keyExpansion (
    input  [127:0] key,
    output [1407:0] fullkeys
);

    // ------------------------------------------------------------
    // AES-128 parameters
    // ------------------------------------------------------------
    localparam Nk = 4;   // key words
    localparam Nr = 10;  // rounds
    localparam Nb = 4;   // block words

    // ------------------------------------------------------------
    // Rcon table (only MSB byte is non-zero)
    // ------------------------------------------------------------
    function [31:0] rcon;
        input [3:0] i;
        begin
            case (i)
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
    // Word array: 44 × 32-bit words
    // ------------------------------------------------------------
    wire [31:0] w [0:Nb*(Nr+1)-1];

    // Initial key words
    assign w[0] = key[127:96];
    assign w[1] = key[95:64];
    assign w[2] = key[63:32];
    assign w[3] = key[31:0];

    // ------------------------------------------------------------
    // Generate remaining words
    // ------------------------------------------------------------
    genvar i;
    generate
        for (i = Nk; i < Nb*(Nr+1); i = i + 1) begin : KEY_EXPAND
            wire [31:0] temp;
            wire [31:0] rotword;
            wire [31:0] subword;

            assign temp = w[i-1];

            // RotWord
            assign rotword = {temp[23:0], temp[31:24]};

            // SubWord using shared S-box
            wire [7:0] sb0, sb1, sb2, sb3;

            sbox s0 (.a(rotword[31:24]), .sbout(sb0));
            sbox s1 (.a(rotword[23:16]), .sbout(sb1));
            sbox s2 (.a(rotword[15:8 ]), .sbout(sb2));
            sbox s3 (.a(rotword[7 :0 ]), .sbout(sb3));

            assign subword = {sb0, sb1, sb2, sb3};

            // Key schedule rule
            assign w[i] = (i % Nk == 0) ?
                          (w[i-Nk] ^ subword ^ rcon(i/Nk)) :
                          (w[i-Nk] ^ temp);
        end
    endgenerate

    // ------------------------------------------------------------
    // Pack round keys: round 0 → round 10
    // ------------------------------------------------------------
    genvar r;
    generate
        for (r = 0; r <= Nr; r = r + 1) begin : PACK_KEYS
            assign fullkeys[128*r +: 128] = {
                w[4*r + 0],
                w[4*r + 1],
                w[4*r + 2],
                w[4*r + 3]
            };
        end
    endgenerate

endmodule
