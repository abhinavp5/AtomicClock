module clk_divider#(
    COUNT_UP= 6_250_000
) (
    input clk,
    output logic slow_clk  = 1'b0
    
);
    logic [$clog2(COUNT_UP)-1:0] counter = 0;
    always @(posedge clk) begin
        if (counter == (COUNT_UP - 1)) begin
            counter <= 0;
            slow_clk <= ~slow_clk;
        end
        else counter <= counter + 1'b1;
    end
endmodule
