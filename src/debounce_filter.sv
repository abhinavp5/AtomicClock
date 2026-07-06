module Debounce_Filter #(
    parameter DEBOUNCE_LIMIT = 1_000_000   // 20 ms at 50 MHz
) (
    input  i_Clk,
    input  reset,
    input  i_Bouncy,
    output o_Debounced
);

    reg [$clog2(DEBOUNCE_LIMIT)-1:0] r_Count_cs, r_Count_ns;

    reg r_Sample_1_cs, r_Sample_1_ns;
    reg r_Sample_2_cs, r_Sample_2_ns;
    reg r_Debounce_cs, r_Debounce_ns;

    // Current State -- Sequential Logic
    always @(posedge i_Clk or posedge reset) begin
        if (reset) begin
            r_Count_cs    <= 0;
            r_Sample_1_cs <= 1'b0;
            r_Sample_2_cs <= 1'b0;
            r_Debounce_cs <= 1'b0;
        end else begin
            r_Count_cs    <= r_Count_ns;
            r_Sample_1_cs <= r_Sample_1_ns;
            r_Sample_2_cs <= r_Sample_2_ns;
            r_Debounce_cs <= r_Debounce_ns;
        end
    end

    always @(*) begin
        // Defaults hold current values so nothing infers a latch
        r_Sample_1_ns = i_Bouncy;          // 1st synchronizer flop for async button
        r_Sample_2_ns = r_Sample_1_cs;     // 2nd flop
        r_Count_ns    = r_Count_cs;
        r_Debounce_ns = r_Debounce_cs;

        if (r_Sample_1_cs != r_Sample_2_cs)
            r_Count_ns = 0;                     // input still moving: restart timer
        else if (r_Count_cs < DEBOUNCE_LIMIT - 1)
            r_Count_ns = r_Count_cs + 1'b1;     // input stable: keep counting
        else begin
            r_Count_ns    = 0;
            r_Debounce_ns = r_Sample_1_cs;      // stable long enough: accept new level
        end
    end

    assign o_Debounced = r_Debounce_cs;

endmodule
