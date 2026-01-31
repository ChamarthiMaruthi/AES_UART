module invMixColumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    // xtime = multiply by 2 in GF(2^8)
    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = (x[7]) ? ((x << 1) ^ 8'h1b) : (x << 1);
        end
    endfunction

    // x2, x4, x8
    function [7:0] x2;
        input [7:0] x; begin x2 = xtime(x); end
    endfunction

    function [7:0] x4;
        input [7:0] x; begin x4 = xtime(x2(x)); end
    endfunction

    function [7:0] x8;
        input [7:0] x; begin x8 = xtime(x4(x)); end
    endfunction

    // inv multipliers
    function [7:0] mul9;
        input [7:0] x; begin mul9 = x8(x) ^ x; end
    endfunction

    function [7:0] mul11;
        input [7:0] x; begin mul11 = x8(x) ^ x2(x) ^ x; end
    endfunction

    function [7:0] mul13;
        input [7:0] x; begin mul13 = x8(x) ^ x4(x) ^ x; end
    endfunction

    function [7:0] mul14;
        input [7:0] x; begin mul14 = x8(x) ^ x4(x) ^ x2(x); end
    endfunction

    integer c;
    reg [7:0] b0, b1, b2, b3;
    reg [7:0] r0, r1, r2, r3;
    reg [127:0] tmp;

    always @* begin
        tmp = 128'h0;
        for (c = 0; c < 4; c = c + 1) begin

            b0 = state_in[127 - ((4*c+0)*8) -: 8];
            b1 = state_in[127 - ((4*c+1)*8) -: 8];
            b2 = state_in[127 - ((4*c+2)*8) -: 8];
            b3 = state_in[127 - ((4*c+3)*8) -: 8];

            r0 = mul14(b0) ^ mul11(b1) ^ mul13(b2) ^ mul9(b3);
            r1 = mul9(b0)  ^ mul14(b1) ^ mul11(b2) ^ mul13(b3);
            r2 = mul13(b0) ^ mul9(b1) ^ mul14(b2) ^ mul11(b3);
            r3 = mul11(b0) ^ mul13(b1) ^ mul9(b2) ^ mul14(b3);

            tmp[127 - ((4*c+0)*8) -: 8] = r0;
            tmp[127 - ((4*c+1)*8) -: 8] = r1;
            tmp[127 - ((4*c+2)*8) -: 8] = r2;
            tmp[127 - ((4*c+3)*8) -: 8] = r3;
        end
    end

    assign state_out = tmp;

endmodule
