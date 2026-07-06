module d_ff(
    input        clk,
    input        D,
    output logic Q
);
    always_ff @(posedge clk) begin
        Q <= D;
    end
endmodule
