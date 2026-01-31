
module decryptRound (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);
    wire [127:0] after_isr;
    wire [127:0] after_isb;
    wire [127:0] after_xor;
    wire [127:0] after_imc;

    inverseShiftRows isr (.in(state_in), .out(after_isr));
    inverseSubBytes isb (.in(after_isr), .out(after_isb));
    assign after_xor = after_isb ^ round_key;
    invMixColumns imc (.state_in(after_xor), .state_out(after_imc));

    assign state_out = after_imc;
endmodule
