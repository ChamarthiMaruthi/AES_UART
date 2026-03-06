module mixColumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    // ------------------------------------------------------------
    // GF(2^8) multiply helpers
    // ------------------------------------------------------------
    function [7:0] xtime(input [7:0] x);
        xtime = x[7] ? ((x << 1) ^ 8'h1b) : (x << 1);
    endfunction

    function [7:0] mul2(input [7:0] x);
        mul2 = xtime(x);
    endfunction

    function [7:0] mul3(input [7:0] x);
        mul3 = xtime(x) ^ x;
    endfunction

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------
    reg [127:0] tmp;
    reg [7:0] b0, b1, b2, b3;
    reg [7:0] x0, x1, x2, x3;
    integer c;

    // ------------------------------------------------------------
    // MixColumns logic
    // ------------------------------------------------------------
    always @* begin
        tmp = 128'd0;

        // Process each of the 4 columns
        for (c = 0; c < 4; c = c + 1) begin

            // Extract one column (4 bytes)
            b0 = state_in[127 - (4*c + 0)*8 -: 8];
            b1 = state_in[127 - (4*c + 1)*8 -: 8];
            b2 = state_in[127 - (4*c + 2)*8 -: 8];
            b3 = state_in[127 - (4*c + 3)*8 -: 8];

            // Apply AES MixColumns matrix
            tmp[127 - (4*c + 0)*8 -: 8] = mul2(b0) ^ mul3(b1) ^ b2       ^ b3;
            tmp[127 - (4*c + 1)*8 -: 8] = b0       ^ mul2(b1) ^ mul3(b2) ^ b3;
            tmp[127 - (4*c + 2)*8 -: 8] = b0       ^ b1       ^ mul2(b2) ^ mul3(b3);
            tmp[127 - (4*c + 3)*8 -: 8] = mul3(b0) ^ b1       ^ b2       ^ mul2(b3);
        end
    end

    // ------------------------------------------------------------
    // Output
    // ------------------------------------------------------------
    assign state_out = tmp;

endmodule
