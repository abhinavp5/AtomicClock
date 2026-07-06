module top(
    input Clk,       // 50 MHz board clock (PIN_P11)
    input  [1:0] KEY,       // 2 pushbuttons, active-low
    input  [9:0] SW,        // 10 slide switches
    // 7-segment displays (one 7-bit bus each), active-low on the board
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5
);

    wire db_button0;
    wire db_button1;
    wire timer_clk;

    wire button0 = ~KEY[0];   // cycle the h-->m-->s-->h...
    wire button1 = ~KEY[1];   // apply the digit change

    // Control switches
    wire en        = SW[0];
    wire increment = SW[1];   // 1 = count up, 0 = count down while setting
    wire set_en    = SW[4];   // enter set mode
    wire reset     = SW[9];

    // 50 MHz --> 1 Hz clock 50% duty cycle
    clk_divider #(
        .COUNT_UP(25_000_000)
    ) my_fast_clk_divider (
        .clk(Clk),
        .slow_clk(timer_clk)
    );

    Debounce_Filter #(.DEBOUNCE_LIMIT(1_000_000)) db_filter0 (
        .i_Clk(Clk),
        .reset(reset),
        .i_Bouncy(button0),
        .o_Debounced(db_button0)
    );

    Debounce_Filter #(.DEBOUNCE_LIMIT(1_000_000)) db_filter1 (
        .i_Clk(Clk),
        .reset(reset),
        .i_Bouncy(button1),
        .o_Debounced(db_button1)
    );

    logic timer_clk_d, db_button0_d, db_button1_d;
    always @(posedge Clk) begin
        timer_clk_d  <= timer_clk;
        db_button0_d <= db_button0;
        db_button1_d <= db_button1;
    end
    wire tick_1hz     = timer_clk  & ~timer_clk_d;
    wire button0_pulse = db_button0 & ~db_button0_d;
    wire button1_pulse = db_button1 & ~db_button1_d;

    wire [5:0][6:0] hex_displays;   // [digit][segment]

    atomic_clock atomic_clock0(
        .clk(Clk),                    // 50 MHz
        .tick(tick_1hz),              // 1 Hz advance pulse
        .reset(reset),
        .en(en),
        .set_en(set_en),
        .increment(increment),        
        .uot_cycle(button0_pulse),    
        .digit_change(button1_pulse), 
        .hex_displays(hex_displays)
    );

    // Board 7-seg segments are active-low, so invert the active-high decoder output
    assign HEX0 = ~hex_displays[0];
    assign HEX1 = ~hex_displays[1];
    assign HEX2 = ~hex_displays[2];
    assign HEX3 = ~hex_displays[3];
    assign HEX4 = ~hex_displays[4];
    assign HEX5 = ~hex_displays[5];

endmodule
