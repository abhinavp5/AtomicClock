module atomic_clock(
    input clk,           // 50 MHz system clock
    input tick,          // 1-cycle-wide pulse @ 1 Hz (advances RUN_CLOCK)
    input reset,
    input en,            // gate RUN_CLOCK counting
    input set_en,
    input increment,
    input uot_cycle,     // 1-cycle pulse: cycle which digit group is being set
    input digit_change,  // 1-cycle pulse: apply +/- to current digit group
    output logic [5:0][6:0] hex_displays
);
    /*
    if the AtomicClock is enabled then the displays will be on 
    S1-->Atomoic clock ticks normally
    S2-->Atomic displays all 0s need to be reset
    S5-->Digit 5  can be freely incremented or decremented
    S4-->Digit 4  can be freely incremented or decremented
    S3-->Digit 3  can be freely incremented or decremented
    S2-->Digit 2  can be freely incremented or decremented
    S1-->Digit 1  can be freely incremented or decremented
    S0-->Digit 0  can be freely incremented or decremented
    */
    typedef enum logic [2:0]
    {  
        RUN_CLOCK,
        SET_DIG54, // Hours
        SET_DIG32, // Minutes
        SET_DIG10 // Seconds 
    } state_t;

    state_t current_state;
    state_t next_state;

    always @(posedge clk)begin
        if(reset) current_state <= RUN_CLOCK;
        else current_state <= next_state;
    end
    
    // FSM Transition Logic
    always_comb begin
        next_state = current_state;   // default: hold state (prevents latch inference)
        case (current_state)
            RUN_CLOCK: if (set_en) next_state = SET_DIG54;
            SET_DIG54: if (!set_en)       next_state = RUN_CLOCK;
                       else if (uot_cycle) next_state = SET_DIG32;
            SET_DIG32: if (!set_en)       next_state = RUN_CLOCK;
                       else if (uot_cycle) next_state = SET_DIG10;
            SET_DIG10: if (!set_en)       next_state = RUN_CLOCK;
                       else if (uot_cycle) next_state = SET_DIG54;
            default: next_state = current_state;
        endcase
    end
    
    logic [3:0] dec_digits [5:0]; //6 digits each holding 4 bits of bcd data
    wire [7:0] seconds = {dec_digits[1], dec_digits[0]};
    wire [7:0] minutes = {dec_digits[3], dec_digits[2]};
    wire [7:0] hours = {dec_digits[5], dec_digits[4]};

    genvar i;
    logic [6:0] seg_wires [5:0];
    generate
        for (i = 0; i < 6; i++) begin : gen_decoders
            bcd_to_7seg u_hex_display (
                .bcd_digit(dec_digits[i]),
                .segments(seg_wires[i])
            );
        end
    endgenerate
    
   // FSM core logics  should toggle on slow clock 
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            for (int k = 0 ; k < 6;k++) begin
                dec_digits[k] <= 4'h0;
            end
        else begin
            case (current_state)
                RUN_CLOCK: if (en && tick) begin
                    // 10 -> [00-59]
                    // 32 -> [00-59]
                    // 65 -> [01-12]
                    if (seconds == 8'h59) begin
                        dec_digits[1] <= 4'h0;
                        dec_digits[0] <= 4'h0;

                        if (minutes == 8'h59) begin
                            dec_digits[3] <= 4'h0;
                            dec_digits[2] <= 4'h0;
                            if (hours == 8'h12) begin
                                dec_digits[5] <= 4'h0;
                                dec_digits[4] <= 4'h1;
                            end else begin
                                if (dec_digits[4] == 4'd9) begin
                                    dec_digits[5] <= dec_digits[5]+1;
                                    dec_digits[4] <= 4'h0;
                                end else begin
                                    dec_digits[4] <= dec_digits[4] + 1;
                                end
                            end
                        
                        end else begin
                            if (dec_digits[2] == 4'd9) begin
                                dec_digits[3] <= dec_digits[3] + 1;
                                dec_digits[2] <= 4'h0;
                            end else begin
                                dec_digits[2] <= dec_digits[2] + 1;
                            end
                        end
                    end else begin
                        if (dec_digits[0] == 4'd9) begin
                            dec_digits[1] <= dec_digits[1] + 1;
                            dec_digits[0] <= 4'h0;
                        end else begin
                            dec_digits[0] <= dec_digits[0] + 1;
                        end
                    end
                end
                SET_DIG54:begin
                    if (increment) begin
                        if (digit_change) begin
                            if (hours == 8'h12) begin
                                // Reset the digit from 12--> 0
                                dec_digits[5] <= 4'd0;
                                dec_digits[4] <= 4'd1;
                            end else if (dec_digits[4] == 4'd9) begin
                                dec_digits[5] <= 4'd1;
                                dec_digits[4] <= 4'd0;
                            end else begin
                                dec_digits[4] <= dec_digits[4]+1;
                            end
                        end
                    end else begin
                        if (digit_change) begin
                            if (hours == 8'h01) begin
                                // Reset the digit from 12--> 0
                                dec_digits[5] <= 4'd1;
                                dec_digits[4] <= 4'd2;
                            end else if (hours == 8'h10) begin
                                dec_digits[5] <= 4'd0;
                                dec_digits[4] <= 4'd9;
                            end else begin
                                dec_digits[4] <= dec_digits[4]-1;
                            end
                        end
                    end 
                end
                SET_DIG32: begin 
                    if (increment) begin
                        if (digit_change) begin
                            if (minutes == 8'h59) begin
                                // Reset the digit from 12--> 0
                                dec_digits[3] <= 4'd0;
                                dec_digits[2] <= 4'd0;
                            end else if (dec_digits[2] == 4'd9) begin
                                dec_digits[3] <= dec_digits[3] +1;
                                dec_digits[2] <= 4'd0;
                            end else begin
                                dec_digits[2] <= dec_digits[2]+1;
                            end
                        end
                    end else begin
                        if (digit_change) begin
                            if (minutes == 8'h00) begin
                                dec_digits[3] <= 4'd5;
                                dec_digits[2] <= 4'd9;
                            end else if (dec_digits[3] == 4'd0) begin
                                dec_digits[3] <= dec_digits[3]-1;
                                dec_digits[2] <= 4'd9;
                            end else if (dec_digits[2] == 4'd0) begin
                                dec_digits[3] <= dec_digits[3]-1;
                                dec_digits[2] <= 4'd9;
                            end else begin
                                dec_digits[2] <= dec_digits[2]-1;
                            end
                        end
                    end
                end
                SET_DIG10: begin 
                    if (increment) begin
                        if (digit_change) begin
                            if (seconds == 8'h59) begin
                                dec_digits[1] <= 4'd0;
                                dec_digits[0] <= 4'd0;
                            end else if (dec_digits[0] == 4'd9) begin
                                dec_digits[1] <= dec_digits[1] +1;
                                dec_digits[0] <= 4'd0;
                            end else begin
                                dec_digits[0] <= dec_digits[0]+1;
                            end
                        end
                    end else begin
                        if (digit_change) begin
                            if (seconds == 8'h00) begin
                                dec_digits[1] <= 4'd5;
                                dec_digits[0] <= 4'd9;
                            end else if (dec_digits[1] == 4'd0) begin
                                dec_digits[1] <= dec_digits[1]-1;
                                dec_digits[0] <= 4'd9;
                            end else if (dec_digits[0] == 4'd0) begin
                                dec_digits[1] <= dec_digits[1]-1;
                                dec_digits[0] <= 4'd9;
                            end else begin
                                dec_digits[0] <= dec_digits[0]-1;
                            end
                        end
                    end
                end
            endcase
        end
    end

    // Final Assignemnets
    always_comb begin
        for (int m = 0; m < 6; m++) begin
            hex_displays[m] = seg_wires[m];
        end
    end
endmodule   
