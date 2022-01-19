`timescale 1 ns / 1 ps

module timer_axi_slave_v1_0_S00_AXI #(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 5,
    
    // Users to add parameters here
    parameter [0:0]	OPT_LOWPOWER   = 1'b0,
    parameter	    ADDRLSB        = $clog2(C_S_AXI_DATA_WIDTH)-3
    // User parameters ends
)(
    // Users to add ports here
    output  wire timer_irq,
    // User ports ends
    // Do not modify the ports beyond this line
    
    input	wire S_AXI_ACLK,
    input	wire S_AXI_ARESETN,
    
    input	wire S_AXI_AWVALID,
    output	wire S_AXI_AWREADY,
    input	wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input	wire [2:0] S_AXI_AWPROT,
    
    input	wire S_AXI_WVALID,
    output	wire S_AXI_WREADY,
    input	wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input	wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    
    output	wire S_AXI_BVALID,
    input	wire S_AXI_BREADY,
    output	wire [1:0] S_AXI_BRESP,
    
    input	wire S_AXI_ARVALID,
    output	wire S_AXI_ARREADY,
    input	wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input	wire [2:0] S_AXI_ARPROT,
    
    output	wire S_AXI_RVALID,
    input	wire S_AXI_RREADY,
    output	wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output	wire [1:0] S_AXI_RRESP
);


/***********************************************************************
 *
 * Register/wire signal declarations
 * 
 ***********************************************************************/

wire [C_S_AXI_ADDR_WIDTH-ADDRLSB-1:0] awskd_addr;
wire [C_S_AXI_DATA_WIDTH-1:0]	      wskd_data;
wire [C_S_AXI_DATA_WIDTH/8-1:0]	      wskd_strb;
wire [C_S_AXI_ADDR_WIDTH-ADDRLSB-1:0] arskd_addr;
reg	 [C_S_AXI_DATA_WIDTH-1:0]	      axil_read_data = 0;
wire axil_write_ready;
wire axil_read_ready;
reg	 axil_bvalid     = 1'b0;
reg	 axil_read_valid = 1'b0;


reg	 [31:0]	timer_conf_reg    = 1'b0;
reg	 [31:0]	timer_cmp_high    = 1'b0;
reg	 [31:0]	timer_cmp_low     = 1'b0;

wire [63:0] counter;
wire [31:0]	timer_value_high  = counter[63:32];
wire [31:0]	timer_value_low   = counter[31:0];

reg overflow                  = 1'b0;
wire done;
wire [31:0] timer_conf_wire   = {timer_conf_reg[31:28], overflow, 27'd0};

wire [31:0]	wskd_timer_conf_reg;
wire [31:0]	wskd_timer_cmp_high;
wire [31:0]	wskd_timer_cmp_low;

/***********************************************************************
 *
 * AXI-Lite signaling
 * 
 ***********************************************************************/

/****** Write signaling *****/

reg axil_awready = 1'b0;

always @(posedge S_AXI_ACLK) begin
    if(!S_AXI_ARESETN) begin
        axil_awready <= 1'b0;
    end
    else begin
        axil_awready <= !axil_awready && (S_AXI_AWVALID && S_AXI_WVALID) && (!S_AXI_BVALID || S_AXI_BREADY);
    end
end

assign S_AXI_AWREADY    = axil_awready;
assign S_AXI_WREADY     = axil_awready;
assign awskd_addr       = S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH-1:ADDRLSB];
assign wskd_data        = S_AXI_WDATA;
assign wskd_strb        = S_AXI_WSTRB;
assign axil_write_ready = axil_awready;


always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axil_bvalid <= 1'b0;
    end
    else if (axil_write_ready) begin
        axil_bvalid <= 1'b1;
    end
    else if (S_AXI_BREADY) begin
        axil_bvalid <= 1'b0;
    end
end

assign S_AXI_BVALID = axil_bvalid;
assign S_AXI_BRESP  = 2'b00;


/****** Read signaling *****/

reg	axil_arready;

always @(*) begin
    axil_arready = !S_AXI_RVALID;
end

assign arskd_addr      = S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH-1:ADDRLSB];
assign S_AXI_ARREADY   = axil_arready;
assign axil_read_ready = (S_AXI_ARVALID && S_AXI_ARREADY);


always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axil_read_valid <= 1'b0;
    end
    else if (axil_read_ready) begin
        axil_read_valid <= 1'b1;
    end
    else if (S_AXI_RREADY) begin
        axil_read_valid <= 1'b0;
    end
end

assign S_AXI_RVALID = axil_read_valid;
assign S_AXI_RDATA  = axil_read_data;
assign S_AXI_RRESP  = 2'b00;


/***********************************************************************
 *
 * AXI-Lite register logic
 * 
 ***********************************************************************/

assign wskd_timer_conf_reg   = apply_wstrb(timer_conf_reg, wskd_data, wskd_strb);
assign wskd_timer_cmp_high   = apply_wstrb(timer_cmp_high, wskd_data, wskd_strb);
assign wskd_timer_cmp_low    = apply_wstrb(timer_cmp_low, wskd_data, wskd_strb);

always @(posedge S_AXI_ACLK) begin
    if(!S_AXI_ARESETN) begin
        timer_conf_reg   <= 32'd0;
        timer_cmp_high   <= 32'd0;
        timer_cmp_low    <= 32'd0;
    end 
    else begin
        /* Overflow bit is only set if interrupt is disabled */
        if(done & ~timer_conf_reg[29]) begin
            overflow <= 1'b1;
        end
        if(axil_write_ready) begin
            case(awskd_addr)
                3'h0: begin
                    timer_conf_reg   <= wskd_timer_conf_reg;
                    if(wskd_timer_conf_reg[27] == 1'b0) begin
                        overflow <= 1'b0;
                    end
                end
                3'h3: timer_cmp_high   <= wskd_timer_cmp_high;
                3'h4: timer_cmp_low    <= wskd_timer_cmp_low;
            endcase
        end
        else begin
            timer_conf_reg[31] <= 1'b0;
        end
    end
end

always @(posedge S_AXI_ACLK) begin
    if (OPT_LOWPOWER && !S_AXI_ARESETN) begin
        axil_read_data <= 0;
    end
    else if (!S_AXI_RVALID || S_AXI_RREADY) begin
        case(arskd_addr)
            3'h0: axil_read_data <= timer_conf_wire;
            3'h1: axil_read_data <= timer_value_high;
            3'h2: axil_read_data <= timer_value_low;
            3'h3: axil_read_data <= timer_cmp_high;
            3'h4: axil_read_data <= timer_cmp_low;
        endcase
    
        if (OPT_LOWPOWER && !axil_read_ready) begin
            axil_read_data <= 0;
        end
    end
end

function  [C_S_AXI_DATA_WIDTH-1:0]	 apply_wstrb;

    input [C_S_AXI_DATA_WIDTH-1:0]   prior_data;
    input [C_S_AXI_DATA_WIDTH-1:0]   new_data;
    input [C_S_AXI_DATA_WIDTH/8-1:0] wstrb;

    integer	k;
    for(k = 0; k < C_S_AXI_DATA_WIDTH/8; k = k + 1) begin
        apply_wstrb[k*8 +: 8] = wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
    end
endfunction


/***********************************************************************
 *
 * Timer
 * 
 ***********************************************************************/

timer uut(
    .clk(S_AXI_ACLK), 
    .rst(S_AXI_ARESETN), 
    .cmp_value({timer_cmp_high, timer_cmp_low}),
    .start_timer(timer_conf_reg[31]),
    .timer_en(timer_conf_reg[30]),
    .interrupt_en(timer_conf_reg[29]),
    .auto_reload(timer_conf_reg[28]),
    .done(done),
    .irq(timer_irq),
    .counter(counter)
);

endmodule