module decryptRound (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);
    wire [127:0] after_xor;
    wire [127:0] after_imc;
    wire [127:0] after_isr;
    wire [127:0] after_isb;

    assign after_xor = state_in ^ round_key;
    inverseMixColumns imc (.state_in(after_xor), .state_out(after_imc));
    inverseShiftRows isr (.in(after_imc), .out(after_isr));
    inverseSubBytes isb (.in(after_isr), .out(after_isb));

    assign state_out = after_isb;
endmodule