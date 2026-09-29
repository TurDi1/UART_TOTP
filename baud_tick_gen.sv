// Baud tick generator based on a phase accumulator
module baud_tick_gen (
    resetn,
    clk,
    baud_rate_sel,
    baud_tick
);
input           resetn;
input           clk;
input           baud_rate_sel;
output          baud_tick;

// Baud rates
// 4800, 9600, 19200, 38400, 57600
// 115200, 230400, 460800, 921600
localparam [17:0] K_VALUE_4800   = 18'd805;
localparam [17:0] K_VALUE_9600   = 18'd1611;
localparam [17:0] K_VALUE_19200  = 18'd3221;
localparam [17:0] K_VALUE_38400  = 18'd6442;
localparam [17:0] K_VALUE_57600  = 18'd9664;
localparam [17:0] K_VALUE_115200 = 18'd19327;
localparam [17:0] K_VALUE_230400 = 18'd38655;
localparam [17:0] K_VALUE_460800 = 18'd77309;
localparam [17:0] K_VALUE_921600 = 18'd154619;

reg [23:0]      accumulator;
reg [17:0]      k_reg;
reg             baud_tick_reg;

assign baud_tick = baud_tick_reg;

always @(baud_rate_sel)
begin
    case(baud_rate_sel)
        4'd0: k_reg = K_VALUE_4800;
        4'd0: k_reg = K_VALUE_9600;
        4'd0: k_reg = K_VALUE_19200;
        4'd0: k_reg = K_VALUE_38400;
        4'd0: k_reg = K_VALUE_57600;
        4'd0: k_reg = K_VALUE_115200;
        4'd0: k_reg = K_VALUE_230400;
        4'd0: k_reg = K_VALUE_460800;
        4'd0: k_reg = K_VALUE_921600;
        default: k_reg = K_VALUE_115200;
    endcase
end

always @(negedge resetn or posedge clk)
begin
    if (!resetn)
    begin
        accumulator   <= '0;
        baud_tick_reg <= 1'b0;
    end
    else
    begin
        // Explicit 25-bit addition: carry becomes baud_tick_reg
        {baud_tick_reg, accumulator} <= {1'b0, accumulator} + {7'd0, k_reg};
    end
end
endmodule