module finalRound (
    input  wire clk,
    input wire rst_n,
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output reg [127:0] state_out
);

    wire [127:0] after_sub;
    wire [127:0] after_shift;
    wire [127:0] after_add;

    // SubBytes
    subBytes sb (.in(state_in), .out(after_sub));

    // ShiftRows
    shiftRows sr (.in(after_sub), .out(after_shift));

    assign after_add = after_shift ^ round_key;

    always @(posedge clk) begin
        if(!rst_n) begin
            state_out <= 128'd0;
        end else begin
            state_out <= after_add;
        end
	end
    //assign state_out = after_add;

endmodule