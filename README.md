# Timer
This unit provides a simple timer with an AXI-Lite interface. It has 5 32bits registers, which are explained below.

## Registers
### timer_conf_reg[31:0]
| Bits | Access | Description |
| ------ | ----------- | ------ |
| 31 | W | **Start**: This bit starts the timer. It is cleared by hardware |
| 30 | W | **EN**: This bit enables the timer unit. |
| 29 | W | **INT**: This bit enables the timer interrupt. If set, an interrupt will occur for each overflow. |
| 28  | W | **Auto Reload**: This bit enables the auto-reload mode. If set, the timer will start again after each overflow. |
| 27  | R | **Overflow**: This bit indicates that the timer reached the desired value (counter == compare_value). It is cleared by hardware when INT is enabled. |
| [26:0] | - | **Unused** |

### timer_value_high[31:0] and timer_value_low[31:0]
These registers contain the current counter (which is incremented by 1 each clock cycle). You can only read from them.

### timer_cmp_high[31:0] and timer_cmp_low[31:0]
Compare registers. 



