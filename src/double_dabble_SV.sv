/*
 * Copyright (c) 2026 Ole Moller
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module double_dabble_SV ( // Leading module name "tt_um_ole_moller_" temporarily removed.
    input  wire [7:0] bin,      // 
    output wire [6:0] segments, //
    output wire       seperator, //
    output wire [7:0] bcd 
);

// Parameters
localparam N = 8;
localparam M = 3; // ceil(log10(2^N-1)) = ceil(log10(2^N)) = ceil(N*log10(2)) ~ ceil(N*0.301029995), N >= 2

// Internal signals
wire [4*M-1:0] bcd_all;
assign bcd   = bcd[7:0];

// ============================================================
// Double dabble: combinational binary-to-BCD conversion
// ============================================================
wire [4*M-1:0] bcd_reg [0:N];
assign bcd_reg[0] = {4*M{1'b0}};

genvar i, j;
generate
	for (i = 0; i < N; i = i + 1) begin : outer_loop // Bits from bin input
        wire [4*M-1:0] temp_bcd;
		for (j = 0; j < M; j = j + 1) begin : inner_loop // BCD digits
            // Add 3 if BCD digit >= 5 (corresponds to adding 6 after left shift)
            // This is the difference between greatest hexadecimal and decimal digit.
            wire [3:0] corr_digit;
            assign corr_digit = (bcd_reg[i][4*j+3 -: 4] >= 4'd5) ? 4'd3 : 4'd0;
            assign temp_bcd[4*j+3 -: 4] = bcd_reg[i][4*j+3 -: 4] + corr_digit;
        end
        assign bcd_reg[i+1] = {temp_bcd[4*M-2:0], bin[N-1-i]};
    end
endgenerate

assign bcd = bcd_reg[N];

// ============================================================
// Clock divider: divide-by-4 counter with enable
// ============================================================
reg [1:0] clk_cnt;
reg clk4_en;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 2'd0;
        clk4_en <= 1'b0;
    end else begin
        clk_cnt <= clk_cnt + 2'd1;
        clk4_en <= (clk_cnt == 2'd3);
    end
end

// ============================================================
// Display state machine with input change detection
// State updates on negedge clk so outputs are stable when
// cocotb samples at posedge clk.
// ============================================================
localparam [1:0] IDLE     = 2'b00,
                 HUNDREDS = 2'b01,
                 TENS     = 2'b10,
                 ONES     = 2'b11;

reg [1:0] state, next_state;
reg [3:0] bcd_digit;
reg [N-1:0] last_bin;

always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= IDLE;
        last_bin <= {N{1'b0}};
    end else if (bin != last_bin) begin
        state    <= IDLE;
        last_bin <= bin;
    end else if (clk4_en) begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        IDLE:     next_state = HUNDREDS;
        HUNDREDS: next_state = TENS;
        TENS:     next_state = ONES;
        ONES:     next_state = IDLE;
        default:  next_state = IDLE;
    endcase
end

always @(*) begin
    case (state)
        IDLE:     bcd_digit = 4'b0000;
        HUNDREDS: bcd_digit = bcd[11:8];
        TENS:     bcd_digit = bcd[7:4];
        ONES:     bcd_digit = bcd[3:0];
        default:  bcd_digit = 4'b0000;
    endcase
end

// ============================================================
// 7-segment decoder (active high, gfedcba)
// ============================================================
reg [6:0] seg_lut;
always @(*) begin
    case (bcd_digit)
        4'd0:  seg_lut = 7'b0111111;
        4'd1:  seg_lut = 7'b0000110;
        4'd2:  seg_lut = 7'b1011011;
        4'd3:  seg_lut = 7'b1001111;
        4'd4:  seg_lut = 7'b1100110;
        4'd5:  seg_lut = 7'b1101101;
        4'd6:  seg_lut = 7'b1111101;
        4'd7:  seg_lut = 7'b0000111;
        4'd8:  seg_lut = 7'b1111111;
        4'd9:  seg_lut = 7'b1101111;
        4'd10: seg_lut = 7'b1110111;
        4'd11: seg_lut = 7'b1111100;
        4'd12: seg_lut = 7'b0111001;
        4'd13: seg_lut = 7'b1011110;
        4'd14: seg_lut = 7'b1111001;
        4'd15: seg_lut = 7'b1110001;
        default: seg_lut = 7'b0000000;
    endcase
end

// Separator state blanks segments and lights decimal point
assign separator = (state == IDLE);
assign segments = separator ? 7'b0000000 : seg_lut;

endmodule
