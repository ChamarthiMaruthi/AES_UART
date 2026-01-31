
module inverseSubBytes (
    input  wire [127:0] in,
    output wire [127:0] out
);

	 /*always @(*) begin
    $display("time=%0t ISB in=%h out=%h", $time, in, out);
	 end*/

    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : ISB
            inverseSbox isb (.a(in[127 - 8*i -: 8]), .sbout(out[127 - 8*i -: 8]));
        end
    endgenerate

endmodule
