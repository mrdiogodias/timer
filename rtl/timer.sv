`timescale 1ns / 1ps


module timer(
    input  wire clk,
    input  wire rst,
    input  wire [63:0] cmp_value,
    input  wire start_timer,
    input  wire timer_en,
    input  wire interrupt_en,
    input  wire auto_reload,

    output wire done,
    output wire irq,
    output wire [63:0] counter
);

wire count;

timer_dp datapath(
    .clk(clk),
    .rst(rst),
    .count(count),
    .cmp_value(cmp_value),
    .done(done),
    .counter(counter)
);

timer_cu control_unit(
    .clk(clk),
    .rst(rst),
    .start(start_timer),   
    .timer_en(timer_en),
    .int_en(interrupt_en),  
    .done(done),    
    .auto_reload(auto_reload),
    .irq(irq),
    .count(count)
);

endmodule