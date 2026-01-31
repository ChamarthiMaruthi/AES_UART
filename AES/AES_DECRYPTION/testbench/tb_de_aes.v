`timescale 1ns/1ps

module tb_de_aes;

    reg clk;
    reg rst_n;
    reg start;
    reg [127:0] ciphertext;
    reg [127:0] key;
    wire [127:0] plaintext;
    wire done;
    reg[1407:0] fullkeys_ref = 0;

    // -----------------------------
    // DUT
    // -----------------------------
    ADS_TOP dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .ciphertext(ciphertext),
        .key(key),
        .plaintext(plaintext),
        .done(done)
    );

    // -----------------------------
    // Clock: 100 MHz
    // -----------------------------
    initial begin
        clk = 1;
        forever #160 clk = ~clk;
    end
    //always #5 clk = ~clk;

    // ============================================================
    // DRIVER
    // ============================================================
    task aes_send_block(input [127:0] ct, input [127:0] k);
    begin
        //@(posedge clk);
        ciphertext <= ct;
        key       <= k;
        start     <= 1'b1;

        @(posedge clk);
        start     <= 1'b0;
    end
    endtask
    
    // ============================================================
    // SCOREBOARD / MONITOR STATE
    // ============================================================
    integer i;
    integer pass_count = 0;
    integer fail_count = 0;

    reg [127:0] expected_plaintext = 0;

    // latency / handshake tracking
    integer latency_cnt = 0;
    integer latency_ref = 11;
    integer latency_err = 0;
    reg     in_flight = 0;
    reg     done_d = 0;
    reg [127:0] pt_prev;
    
    
    
    // ============================================================
    // MONITOR + CHECKERS
    // ============================================================
    always @(posedge clk) begin
        done_d <= done;

        if (!rst_n) begin
            latency_cnt <= 0;
            in_flight   <= 0;
            pt_prev     <= ciphertext;
        end else begin

            // start handshake
            if (start && !in_flight) begin
                in_flight   <= 1;
                latency_cnt <= 0;
            end

            if (in_flight && !done)
                latency_cnt <= latency_cnt + 1;

            // done handshake
            if (done && in_flight) begin
                in_flight <= 0;
                $display("time : %0t | Entered done handshake block. pt=%h", $time, plaintext);
                

                if (latency_cnt != latency_ref) begin
                    latency_err <= latency_err + 1;
                    $display("❌ LATENCY ERROR exp=%0d got=%0d",latency_ref, latency_cnt);
                end
            end

            // done must be 1 cycle
            if (done && done_d) begin
                $display("❌ ERROR: done > 1 cycle @ %0t", $time);
                fail_count <= fail_count + 1;
            end

            // ciphertext must not change before done
            if (!rst_n && in_flight && !done && ciphertext !== pt_prev) begin
                $display("❌ ERROR: ciphertext changed before done @ %0t", $time);
                fail_count <= fail_count + 1;
            end

            pt_prev <= plaintext;
        end
    end

    always@(posedge clk) begin
        if(done && in_flight) begin
            if(plaintext === expected_plaintext) begin
                pass_count <= pass_count + 1;
                //$display("PASS | ct=%h | latency=%0d",ciphertext, latency_cnt);
                $display("✅ PASS");
                $display("  Ciphertext : %h", ciphertext);
                $display("  Plaintext  : %h", plaintext);
                $display("  Expected   : %h", expected_plaintext);
            end 
            if(plaintext !== expected_plaintext) begin
                fail_count <= fail_count + 1;
                //$display("time : %0t | FAIL | fail_count=%0d | Expected: %h | Got: %h", $time, fail_count, expected_ciphertext, ciphertext);
                $display("❌ FAIL");
                $display("  Ciphertext : %h", ciphertext);
                $display("  Expected   : %h", expected_plaintext);
                $display("  Got     : %h", plaintext);
            end
        end
    end

    reg [127:0] golden_ciphertext [0:9];

    initial begin
        golden_ciphertext[0] = 128'h00000000000000000000000000000000;
        golden_ciphertext[1] = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        golden_ciphertext[2] = 128'h58e2fccefa7e3061367f1d57a4e7455a;
        golden_ciphertext[3] = 128'h0388dace60b6a392f328c2b971b2fe78;
        golden_ciphertext[4] = 128'hf795aaab494b5923f7fd89ff948bc1e0;
        golden_ciphertext[5] = 128'h200211214e7394da2089b6acd093abe0;
        golden_ciphertext[6] = 128'hc94da219118e297d7b7ebcbcc9c388f2;
        golden_ciphertext[7] = 128'h8ade7d85a8ee35616f7124a9d5270291;
        golden_ciphertext[8] = 128'h95b84d1b96c690ff2f2de30bf2ec89e0;
        golden_ciphertext[9] = 128'h0253786e126504f0dab90c48a30321de;
    end

    reg [127:0] golden_plaintext [0:9];

    initial begin
        golden_plaintext[0] = 128'h140f0f1011b5223d79587717ffd9ec3a;
        golden_plaintext[1] = 128'h00000000000000000000000000000000;
        golden_plaintext[2] = 128'h00000000000000000000000000000001;
        golden_plaintext[3] = 128'h00000000000000000000000000000002;
        golden_plaintext[4] = 128'h00000000000000000000000000000003;
        golden_plaintext[5] = 128'h00000000000000000000000000000004;
        golden_plaintext[6] = 128'h00000000000000000000000000000005;
        golden_plaintext[7] = 128'h00000000000000000000000000000006;
        golden_plaintext[8] = 128'h00000000000000000000000000000007;
        golden_plaintext[9] = 128'h00000000000000000000000000000008;
    end



 
    /*
    // ============================================================
    // REFERENCE AES MODEL (BEHAVIORAL)
    // ============================================================

    function [7:0] sbout;
        input [7:0] a;
        begin
            case (a)
                8'h00: sbout = 8'h52; 8'h01: sbout = 8'h09; 8'h02: sbout = 8'h6a; 8'h03: sbout = 8'hd5;
                8'h04: sbout = 8'h30; 8'h05: sbout = 8'h36; 8'h06: sbout = 8'ha5; 8'h07: sbout = 8'h38;
                8'h08: sbout = 8'hbf; 8'h09: sbout = 8'h40; 8'h0a: sbout = 8'ha3; 8'h0b: sbout = 8'h9e;
                8'h0c: sbout = 8'h81; 8'h0d: sbout = 8'hf3; 8'h0e: sbout = 8'hd7; 8'h0f: sbout = 8'hfb;
                8'h10: sbout = 8'h7c; 8'h11: sbout = 8'he3; 8'h12: sbout = 8'h39; 8'h13: sbout = 8'h82;
                8'h14: sbout = 8'h9b; 8'h15: sbout = 8'h2f; 8'h16: sbout = 8'hff; 8'h17: sbout = 8'h87;
                8'h18: sbout = 8'h34; 8'h19: sbout = 8'h8e; 8'h1a: sbout = 8'h43; 8'h1b: sbout = 8'h44;
                8'h1c: sbout = 8'hc4; 8'h1d: sbout = 8'hde; 8'h1e: sbout = 8'he9; 8'h1f: sbout = 8'hcb;
                8'h20: sbout = 8'h54; 8'h21: sbout = 8'h7b; 8'h22: sbout = 8'h94; 8'h23: sbout = 8'h32;
                8'h24: sbout = 8'ha6; 8'h25: sbout = 8'hc2; 8'h26: sbout = 8'h23; 8'h27: sbout = 8'h3d;
                8'h28: sbout = 8'hee; 8'h29: sbout = 8'h4c; 8'h2a: sbout = 8'h95; 8'h2b: sbout = 8'h0b;
                8'h2c: sbout = 8'h42; 8'h2d: sbout = 8'hfa; 8'h2e: sbout = 8'hc3; 8'h2f: sbout = 8'h4e;
                8'h30: sbout = 8'h08; 8'h31: sbout = 8'h2e; 8'h32: sbout = 8'ha1; 8'h33: sbout = 8'h66;
                8'h34: sbout = 8'h28; 8'h35: sbout = 8'hd9; 8'h36: sbout = 8'h24; 8'h37: sbout = 8'hb2;
                8'h38: sbout = 8'h76; 8'h39: sbout = 8'h5b; 8'h3a: sbout = 8'ha2; 8'h3b: sbout = 8'h49;
                8'h3c: sbout = 8'h6d; 8'h3d: sbout = 8'h8b; 8'h3e: sbout = 8'hd1; 8'h3f: sbout = 8'h25;
                8'h40: sbout = 8'h72; 8'h41: sbout = 8'hf8; 8'h42: sbout = 8'hf6; 8'h43: sbout = 8'h64;
                8'h44: sbout = 8'h86; 8'h45: sbout = 8'h68; 8'h46: sbout = 8'h98; 8'h47: sbout = 8'h16;
                8'h48: sbout = 8'hd4; 8'h49: sbout = 8'ha4; 8'h4a: sbout = 8'h5c; 8'h4b: sbout = 8'hcc;
                8'h4c: sbout = 8'h5d; 8'h4d: sbout = 8'h65; 8'h4e: sbout = 8'hb6; 8'h4f: sbout = 8'h92;
                8'h50: sbout = 8'h6c; 8'h51: sbout = 8'h70; 8'h52: sbout = 8'h48; 8'h53: sbout = 8'h50;
                8'h54: sbout = 8'hfd; 8'h55: sbout = 8'hed; 8'h56: sbout = 8'hb9; 8'h57: sbout = 8'hda;
                8'h58: sbout = 8'h5e; 8'h59: sbout = 8'h15; 8'h5a: sbout = 8'h46; 8'h5b: sbout = 8'h57;
                8'h5c: sbout = 8'ha7; 8'h5d: sbout = 8'h8d; 8'h5e: sbout = 8'h9d; 8'h5f: sbout = 8'h84;
                8'h60: sbout = 8'h90; 8'h61: sbout = 8'hd8; 8'h62: sbout = 8'hab; 8'h63: sbout = 8'h00;
                8'h64: sbout = 8'h8c; 8'h65: sbout = 8'hbc; 8'h66: sbout = 8'hd3; 8'h67: sbout = 8'h0a;
                8'h68: sbout = 8'hf7; 8'h69: sbout = 8'he4; 8'h6a: sbout = 8'h58; 8'h6b: sbout = 8'h05;
                8'h6c: sbout = 8'hb8; 8'h6d: sbout = 8'hb3; 8'h6e: sbout = 8'h45; 8'h6f: sbout = 8'h06;
                8'h70: sbout = 8'hd0; 8'h71: sbout = 8'h2c; 8'h72: sbout = 8'h1e; 8'h73: sbout = 8'h8f;
                8'h74: sbout = 8'hca; 8'h75: sbout = 8'h3f; 8'h76: sbout = 8'h0f; 8'h77: sbout = 8'h02;
                8'h78: sbout = 8'hc1; 8'h79: sbout = 8'haf; 8'h7a: sbout = 8'hbd; 8'h7b: sbout = 8'h03;
                8'h7c: sbout = 8'h01; 8'h7d: sbout = 8'h13; 8'h7e: sbout = 8'h8a; 8'h7f: sbout = 8'h6b;
                8'h80: sbout = 8'h3a; 8'h81: sbout = 8'h91; 8'h82: sbout = 8'h11; 8'h83: sbout = 8'h41;
                8'h84: sbout = 8'h4f; 8'h85: sbout = 8'h67; 8'h86: sbout = 8'hdc; 8'h87: sbout = 8'hea;
                8'h88: sbout = 8'h97; 8'h89: sbout = 8'hf2; 8'h8a: sbout = 8'hcf; 8'h8b: sbout = 8'hce;
                8'h8c: sbout = 8'hf0; 8'h8d: sbout = 8'hb4; 8'h8e: sbout = 8'he6; 8'h8f: sbout = 8'h73;
                8'h90: sbout = 8'h96; 8'h91: sbout = 8'hac; 8'h92: sbout = 8'h74; 8'h93: sbout = 8'h22;
                8'h94: sbout = 8'he7; 8'h95: sbout = 8'had; 8'h96: sbout = 8'h35; 8'h97: sbout = 8'h85;
                8'h98: sbout = 8'he2; 8'h99: sbout = 8'hf9; 8'h9a: sbout = 8'h37; 8'h9b: sbout = 8'he8;
                8'h9c: sbout = 8'h1c; 8'h9d: sbout = 8'h75; 8'h9e: sbout = 8'hdf; 8'h9f: sbout = 8'h6e;
                8'ha0: sbout = 8'h47; 8'ha1: sbout = 8'hf1; 8'ha2: sbout = 8'h1a; 8'ha3: sbout = 8'h71;
                8'ha4: sbout = 8'h1d; 8'ha5: sbout = 8'h29; 8'ha6: sbout = 8'hc5; 8'ha7: sbout = 8'h89;
                8'ha8: sbout = 8'h6f; 8'ha9: sbout = 8'hb7; 8'haa: sbout = 8'h62; 8'hab: sbout = 8'h0e;
                8'hac: sbout = 8'haa; 8'had: sbout = 8'h18; 8'hae: sbout = 8'hbe; 8'haf: sbout = 8'h1b;
                8'hb0: sbout = 8'hfc; 8'hb1: sbout = 8'h56; 8'hb2: sbout = 8'h3e; 8'hb3: sbout = 8'h4b;
                8'hb4: sbout = 8'hc6; 8'hb5: sbout = 8'hd2; 8'hb6: sbout = 8'h79; 8'hb7: sbout = 8'h20;
                8'hb8: sbout = 8'h9a; 8'hb9: sbout = 8'hdb; 8'hba: sbout = 8'hc0; 8'hbb: sbout = 8'hfe;
                8'hbc: sbout = 8'h78; 8'hbd: sbout = 8'hcd; 8'hbe: sbout = 8'h5a; 8'hbf: sbout = 8'hf4;
                8'hc0: sbout = 8'h1f; 8'hc1: sbout = 8'hdd; 8'hc2: sbout = 8'ha8; 8'hc3: sbout = 8'h33;
                8'hc4: sbout = 8'h88; 8'hc5: sbout = 8'h07; 8'hc6: sbout = 8'hc7; 8'hc7: sbout = 8'h31;
                8'hc8: sbout = 8'hb1; 8'hc9: sbout = 8'h12; 8'hca: sbout = 8'h10; 8'hcb: sbout = 8'h59;
                8'hcc: sbout = 8'h27; 8'hcd: sbout = 8'h80; 8'hce: sbout = 8'hec; 8'hcf: sbout = 8'h5f;
                8'hd0: sbout = 8'h60; 8'hd1: sbout = 8'h51; 8'hd2: sbout = 8'h7f; 8'hd3: sbout = 8'ha9;
                8'hd4: sbout = 8'h19; 8'hd5: sbout = 8'hb5; 8'hd6: sbout = 8'h4a; 8'hd7: sbout = 8'h0d;
                8'hd8: sbout = 8'h2d; 8'hd9: sbout = 8'he5; 8'hda: sbout = 8'h7a; 8'hdb: sbout = 8'h9f;
                8'hdc: sbout = 8'h93; 8'hdd: sbout = 8'hc9; 8'hde: sbout = 8'h9c; 8'hdf: sbout = 8'hef;
                8'he0: sbout = 8'ha0; 8'he1: sbout = 8'he0; 8'he2: sbout = 8'h3b; 8'he3: sbout = 8'h4d;
                8'he4: sbout = 8'hae; 8'he5: sbout = 8'h2a; 8'he6: sbout = 8'hf5; 8'he7: sbout = 8'hb0;
                8'he8: sbout = 8'hc8; 8'he9: sbout = 8'heb; 8'hea: sbout = 8'hbb; 8'heb: sbout = 8'h3c;
                8'hec: sbout = 8'h83; 8'hed: sbout = 8'h53; 8'hee: sbout = 8'h99; 8'hef: sbout = 8'h61;
                8'hf0: sbout = 8'h17; 8'hf1: sbout = 8'h2b; 8'hf2: sbout = 8'h04; 8'hf3: sbout = 8'h7e;
                8'hf4: sbout = 8'hba; 8'hf5: sbout = 8'h77; 8'hf6: sbout = 8'hd6; 8'hf7: sbout = 8'h26;
                8'hf8: sbout = 8'he1; 8'hf9: sbout = 8'h69; 8'hfa: sbout = 8'h14; 8'hfb: sbout = 8'h63;
                8'hfc: sbout = 8'h55; 8'hfd: sbout = 8'h21; 8'hfe: sbout = 8'h0c; 8'hff: sbout = 8'h7d;
                default: sbout = 8'h00;
            endcase
        end
    endfunction
    
    
    function automatic [127:0] inv_subbytes_ref(input [127:0] s);
    integer j;
    begin
    	for (j = 0; j < 16; j = j + 1)
        inv_subbytes_ref[127-8*j -: 8] =
            sbout(s[127-8*j -: 8]);
	end
    endfunction
    
    function automatic [127:0] inv_shiftrows_ref(input [127:0] s);
    begin
    	inv_shiftrows_ref = {
        	s[127:120], s[23:16],  s[55:48],  s[87:80],
        	s[95:88],   s[119:112],s[15:8],   s[47:40],
        	s[63:56],   s[111:104],s[7:0],    s[39:32],
        	s[31:24],   s[71:64],  s[103:96], s[79:72]
    	};
    end
    endfunction
    
    function automatic [7:0] xtime;
        input [7:0] x;
        begin
            xtime = (x[7]) ? ((x << 1) ^ 8'h1b) : (x << 1);
        end
    endfunction

    // x2, x4, x8
    function automatic [7:0] x2;
        input [7:0] x; begin x2 = xtime(x); end
    endfunction

    function automatic [7:0] x4;
        input [7:0] x; begin x4 = xtime(x2(x)); end
    endfunction

    function automatic [7:0] x8;
        input [7:0] x; begin x8 = xtime(x4(x)); end
    endfunction

    // inv multipliers
    function automatic [7:0] mul9;
        input [7:0] x; begin mul9 = x8(x) ^ x; end
    endfunction

    function automatic [7:0] mul11;
        input [7:0] x; begin mul11 = x8(x) ^ x2(x) ^ x; end
    endfunction

    function automatic [7:0] mul13;
        input [7:0] x; begin mul13 = x8(x) ^ x4(x) ^ x; end
    endfunction

    function automatic [7:0] mul14;
        input [7:0] x; begin mul14 = x8(x) ^ x4(x) ^ x2(x); end
    endfunction

    function automatic [31:0] inv_mixcol_ref(input [31:0] c);
    reg [7:0] a0,a1,a2,a3;
    begin
    {a0,a1,a2,a3} = c;
    inv_mixcol_ref = {
        mul14(a0)^mul11(a1)^mul13(a2)^mul9(a3),
        mul9(a0)^mul14(a1)^mul11(a2)^mul13(a3),
        mul13(a0)^mul9(a1)^mul14(a2)^mul11(a3),
        mul11(a0)^mul13(a1)^mul9(a2)^mul14(a3)
    };
    end
    endfunction

    
    function automatic [31:0] aes_rcon(input integer i);
    begin
        case (i)
            1: aes_rcon = 32'h01000000;
            2: aes_rcon = 32'h02000000;
            3: aes_rcon = 32'h04000000;
            4: aes_rcon = 32'h08000000;
            5: aes_rcon = 32'h10000000;
            6: aes_rcon = 32'h20000000;
            7: aes_rcon = 32'h40000000;
            8: aes_rcon = 32'h80000000;
            9: aes_rcon = 32'h1b000000;
            10:aes_rcon = 32'h36000000;
            default: aes_rcon = 32'h00000000;
        endcase
    end
    endfunction

        function automatic [31:0] rotword(input [31:0] w);
    begin
        rotword = {w[23:0], w[31:24]};
    end
    endfunction

    function automatic [31:0] subword(input [31:0] w);
    begin
        subword = {
            sbout(w[31:24]),
            sbout(w[23:16]),
            sbout(w[15:8]),
            sbout(w[7:0])
        };
    end
    endfunction

    function automatic [127:0] aes_decrypt_ref(
    input [127:0] ct,
    input [1407:0] fullkeys
    );
    integer r;
    reg [127:0] st;
    begin
    // Initial add round key (last key)
    st = ct ^ fullkeys[128*10 +: 128];

    for (r = 9; r > 0; r = r - 1) begin
        st = inv_shiftrows_ref(st);
        st = inv_subbytes_ref(st);
        st = st ^ fullkeys[128*r +: 128];
        st = {
            inv_mixcol_ref(st[127:96]),
            inv_mixcol_ref(st[95:64]),
            inv_mixcol_ref(st[63:32]),
            inv_mixcol_ref(st[31:0])
        };
    end

    st = inv_shiftrows_ref(st);
    st = inv_subbytes_ref(st);
    aes_decrypt_ref = st ^ fullkeys[0 +: 128];
    end
    endfunction


    function automatic [1407:0] aes_key_expand_ref(input [127:0] key);
    integer i;
    reg [31:0] w [0:43];
    begin
        // Initial key
        for (i = 0; i < 4; i = i + 1)
            w[i] = key[127 - 32*i -: 32];

        // Expand
        for (i = 4; i < 44; i = i + 1) begin
            if (i % 4 == 0)
                w[i] = w[i-4] ^ subword(rotword(w[i-1])) ^ aes_rcon(i/4);
            else
                w[i] = w[i-4] ^ w[i-1];
        end

        // Pack round keys
        for (i = 0; i < 11; i = i + 1)
            aes_key_expand_ref[128*i +: 128] = {
                w[4*i], w[4*i+1], w[4*i+2], w[4*i+3]
            };
    end
    endfunction

    */


    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    reg [127:0] ct_array [0:9];

    initial begin
        for (i = 0; i < 10; i = i + 1)
            ct_array[i] = 128'h0 + i;
    end

    initial begin
        start      = 0;
        ciphertext = 0;
        key        = 0;
        rst_n      = 0;

        pass_count = 0;
        fail_count = 0;
        latency_err = 0;

        repeat (2) @(posedge clk);
        rst_n = 1;
        wait (rst_n == 1);

        key = 128'h00000000000000000000000000000000;
        //fullkeys_ref = aes_key_expand_ref(key);

        // multi-block test
        for (i = 0; i < 10; i = i + 1) begin
            aes_send_block(golden_ciphertext[i], key);
            wait(done);
            //wait(!done);
            //expected_plaintext = aes_decrypt_ref(golden_ciphertext[i], fullkeys_ref);
            expected_plaintext = golden_plaintext[i];
            //repeat(1) begin @(posedge clk); end
            
            //wait (done);
            @(posedge clk);
        end

        // reset during operation
        /*aes_send_block(golden_ciphertext[0], key);
        repeat (5) @(posedge clk);
        rst_n <= 0;
        @(posedge clk);
        rst_n <= 1;
        wait (rst_n == 1);

        expected_plaintext = aes_decrypt_ref(golden_ciphertext[0], fullkeys_ref);
        aes_send_block(golden_ciphertext[0], key);
        wait (done);*/

        // ========================================================
        // FINAL REPORT
        // ========================================================
        $display("----------------------------------");
        $display("AES DECRYPTION TEST SUMMARY");
        $display("PASS        : %0d", pass_count);
        $display("FAIL        : %0d", fail_count);
        $display("LATENCY ERR : %0d", latency_err);
        $display("LATENCY REF : %0d", latency_ref);
        $display("----------------------------------");

        if (fail_count == 0 && latency_err == 0)
            $display("✅ AES DECRYPTION TB PASSED");
        else
            $display("❌ AES DECRYPTION TB FAILED");

        $finish;
    end

    endmodule






