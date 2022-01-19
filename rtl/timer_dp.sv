`timescale 1ns / 1ps



module timer_dp(
    input  wire clk,
    input  wire rst,
    input  wire count,
    input  reg  [63:0] cmp_value,
     
    output reg  done,
    output wire [63:0] counter
);

reg [63:0] counter_reg = 64'd0;

assign counter = counter_reg;

always@(posedge clk) begin 
    if(!rst) begin
        done        = 1'b0;
        counter_reg = 64'd0;
    end 
    else begin
        if(count) begin
            counter_reg <= counter + 1;
        end
        
        if(counter == cmp_value - 1) begin
            done         = 1'b1;
            counter_reg <= 64'd0;
        end 
        else begin
            done = 1'b0;
        end
    end
end

endmodule