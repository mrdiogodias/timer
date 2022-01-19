`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2021 11:49:59 AM
// Design Name: 
// Module Name: systick_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timer_tb;

reg clk              = 1'b0;
reg rst              = 1'b0;
reg [63:0] cmp_value = 64'd25;
reg start_timer      = 1'b0;
reg timer_en         = 1'b1;
reg interrupt_en     = 1'b1;
reg auto_reload      = 1'b1;

wire irq;
wire done;
wire [63:0] counter;

initial begin 
    rst         = 0;
    #15
    rst         = 1;
    start_timer = 1;
    #10
    start_timer = 0;
    
    #100
    timer_en    = 0;
    #50
    timer_en    = 1;
    start_timer = 1;
end

timer uut(
    .clk(clk),
    .rst(rst),
    .cmp_value(cmp_value),
    .start_timer(start_timer),
    .timer_en(timer_en),
    .interrupt_en(interrupt_en),
    .auto_reload(auto_reload),
    .done(done),
    .irq(irq),
    .counter(counter)
);

always #5 clk = ~clk;

endmodule