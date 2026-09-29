// Baud tick generator based on a phase accumulator
module baud_tick_gen (
    resetn,
    clk,
    baud_rate_sel,
    baud_tick_16x
);
input           resetn;
input           clk;
input  [3:0]    baud_rate_sel;
output          baud_tick_16x;

// Baud rates
// 4800, 9600, 19200, 38400, 57600
// 115200, 230400, 460800, 921600
// Baud_tick_16x - baud_rate * 16
localparam [21:0] K_VALUE_4800   = 22'd12885;
localparam [21:0] K_VALUE_9600   = 22'd25770;
localparam [21:0] K_VALUE_19200  = 22'd51540;
localparam [21:0] K_VALUE_38400  = 22'd103079;
localparam [21:0] K_VALUE_57600  = 22'd154619;
localparam [21:0] K_VALUE_115200 = 22'd309238;
localparam [21:0] K_VALUE_230400 = 22'd618475;
localparam [21:0] K_VALUE_460800 = 22'd1236951;
localparam [21:0] K_VALUE_921600 = 22'd2473901;

reg [23:0]      accumulator;
reg [21:0]      k_reg;
reg             baud_tick_reg;

assign baud_tick_16x = baud_tick_reg;

always @(baud_rate_sel)
begin
    case(baud_rate_sel)
        4'd0: k_reg = K_VALUE_4800;
        4'd1: k_reg = K_VALUE_9600;
        4'd2: k_reg = K_VALUE_19200;
        4'd3: k_reg = K_VALUE_38400;
        4'd4: k_reg = K_VALUE_57600;
        4'd5: k_reg = K_VALUE_115200;
        4'd6: k_reg = K_VALUE_230400;
        4'd7: k_reg = K_VALUE_460800;
        4'd8: k_reg = K_VALUE_921600;
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
        {baud_tick_reg, accumulator} <= {1'b0, accumulator} + {3'd0, k_reg};
    end
end
endmodule