module shiftRows (
    input  wire [127:0] in,
    output wire [127:0] out
);

    // -------------------------
    // Row 0 (no shift)
    // -------------------------
    assign out[127:120] = in[127:120]; // s0
    assign out[95:88]   = in[95:88];   // s4
    assign out[63:56]   = in[63:56];   // s8
    assign out[31:24]   = in[31:24];   // s12

    // -------------------------
    // Row 1 (left shift by 1)
    // -------------------------
    assign out[119:112] = in[87:80];   // s5
    assign out[87:80]   = in[55:48];   // s9
    assign out[55:48]   = in[23:16];   // s13
    assign out[23:16]   = in[119:112]; // s1

    // -------------------------
    // Row 2 (left shift by 2)
    // -------------------------
    assign out[111:104] = in[47:40];   // s10
    assign out[79:72]   = in[15:8];    // s14
    assign out[47:40]   = in[111:104]; // s2
    assign out[15:8]    = in[79:72];   // s6

    // -------------------------
    // Row 3 (left shift by 3)
    // -------------------------
    assign out[103:96]  = in[7:0];     // s15
    assign out[71:64]   = in[103:96];  // s3
    assign out[39:32]   = in[71:64];   // s7
    assign out[7:0]     = in[39:32];   // s11

endmodule
