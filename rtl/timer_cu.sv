`timescale 1ns / 1ps


module timer_cu(
    input  wire clk,
    input  wire rst,
    input  wire start,   /* start counting */
    input  wire timer_en,
    input  wire int_en,  /* interrupt enable */
    input  wire done,    /* count finish */
    input  wire auto_reload,
    
    output reg irq,
    output reg count
);

localparam [3:0]  STATE_IDLE  = 4'd0,
                  STATE_COUNT = 4'd1,
                  STATE_STOP  = 4'd2;

wire [3:0] next_state;
reg  [3:0] state   = 4'b0;
reg  activate_int  = 1'b0;
reg  [3:0] clk_cnt = 4'd0;
initial irq        = 1'b0;

assign next_state = (state == STATE_IDLE & start)         ? STATE_COUNT :
                    (state == STATE_IDLE & ~start)        ? STATE_IDLE : 
                    (state == STATE_COUNT & done)         ? STATE_STOP :
                    (state == STATE_COUNT & ~done)        ? STATE_COUNT :
                    (state == STATE_STOP & auto_reload)   ? STATE_COUNT :
                    (state == STATE_STOP & ~auto_reload)  ? STATE_IDLE : STATE_IDLE;
                    
always@(posedge clk) begin
    if(!rst || !timer_en) begin
        state <= STATE_IDLE;
    end 
    else begin
        state <= next_state;
    end
end

always@(posedge clk) begin 
    if(activate_int) begin
        irq      = 1'b1;
        clk_cnt <= 4'd0;
    end
    
    if(irq) begin
        clk_cnt <= clk_cnt + 1;
        if(clk_cnt == 4'd15) begin
            clk_cnt <= 4'd0;
            irq      = 1'b0;
        end
    end
end

always@(*) begin 
    case(state)
            STATE_IDLE: begin
                count        = 1'b0;
                activate_int = 1'b0;
            end
            
            STATE_COUNT: begin
                count        = 1'b1;
                activate_int = 1'b0;
            end
            
            STATE_STOP: begin
                if(auto_reload) begin
                    count = 1'b1;
                end
                else begin
                    count = 1'b0;
                end
                
                if(int_en) begin
                    activate_int = 1'b1;
                end 
                else begin
                    activate_int = 1'b0;
                end
            end
            
            default: begin
                count        = 1'b0;
                activate_int = 1'b0;
            end
    endcase
end

endmodule
