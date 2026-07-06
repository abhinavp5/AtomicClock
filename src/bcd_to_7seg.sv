module bcd_to_7seg (
    input  logic [3:0] bcd_digit,  
    output logic [6:0] segments   
);

    always_comb begin
        case (bcd_digit)
            4'd0: segments = 7'b0111111; // Displays '0'
            4'd1: segments = 7'b0000110; // Displays '1'
            4'd2: segments = 7'b1011011; // Displays '2'
            4'd3: segments = 7'b1001111; // Displays '3'
            4'd4: segments = 7'b1100110; // Displays '4'
            4'd5: segments = 7'b1101101; // Displays '5'
            4'd6: segments = 7'b1111101; // Displays '6'
            4'd7: segments = 7'b0000111; // Displays '7'
            4'd8: segments = 7'b1111111; // Displays '8'
            4'd9: segments = 7'b1101111; // Displays '9'
            default: segments = 7'b0000000; 
        endcase
    end

endmodule
