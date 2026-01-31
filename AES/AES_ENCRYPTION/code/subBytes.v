
module subBytes (
    input  wire [127:0] in,
    output wire [127:0] out
);

    genvar i;

    // Each byte goes into its own S-box
    generate
        for (i = 0; i < 16; i = i + 1) begin : SB_LOOP
            sbox sb_inst (
                .a    ( in[127 - 8*i -: 8] ),
                .sbout( out[127 - 8*i -: 8] )
            );
        end
    endgenerate
	

endmodule