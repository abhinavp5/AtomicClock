### Digital CLock for DE10lite FPGA

| Control | Signal | Function |
|---------|--------|----------|
| SW0 | en | 1 = clock ticks (runs). 0 = frozen |
| SW1 | increment | Direction while setting: 1 = count up, 0 = count down |
| SW4 | set_en | 1 = enter set mode, 0 = run mode |
| SW9 | reset | 1 = hold everything at 00:00:00 (async). Must be 0 to run |
| KEY0 | uot_cycle | Press to cycle which pair you're editing: Hours → Minutes → Seconds → … |
| KEY1 | digit_change | Press to apply one +/- step to the selected pair |
