
module finalInvRound (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);
    wire [127:0] after_isr;
    wire [127:0] after_isb;

    inverseShiftRows isr (.in(state_in), .out(after_isr));
    inverseSubBytes isb (.in(after_isr), .out(after_isb));
    assign state_out = after_isb ^ round_key;
endmodule
