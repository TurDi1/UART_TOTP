module uart_core (
    resetn,
    clk,
    tx,
    rx,
    data_in,
    valid_in,
    busy,
    data_out,
    valid_out,
    baud_rate_sel
);
input              resetn;        // System reset input (active LOW)
input              clk;           // System clock input
output             tx;            // UART TX output
input              rx;            // UART RX input
input   [7:0]      data_in;       // Input data bus to TX
input              valid_in;      // Valid input signal to TX
output             busy;          // TX busy signal from TX
output  [7:0]      data_out;      // Output data bus from RX
output             valid_out;     // Valid output signal from RX
input   [3:0]      baud_rate_sel; // Baud rate selector bus (4800, 9600, 19200, 38400,
                                  // 57600, 115200, 230400, 460800, 921600)
//==================================
//      WIRE'S, REG'S and etc
//==================================
wire               rx_sync;
wire               baud_tick_16x_wire;

//==================================
//         INSTATIATIONS
//==================================
sync #(
    .ff_num         ( 'd2 )
) rx_sync_inst (
    .clk            ( clk ),
    .async_in       ( rx ),
    .sync_out       ( rx_sync )
);

baud_tick_gen baud_gen_inst (
    .resetn         ( resetn ),
    .clk            ( clk ),
    .baud_rate_sel  ( baud_rate_sel ),
    .baud_tick_16x  ( baud_tick_16x_wire )
);

uart_rx rx_inst (
    .resetn         ( resetn ),
    .clk            ( clk ),
    .baud_tick      ( baud_tick_16x_wire ),
    .rx             ( rx_sync ),
    .data           ( data_out ),
    .valid          ( valid_out )
);

/*uart_tx tx_inst (
    .resetn         ( resetn ),
    .clk            ( clk ),
    .baud_tick      ( baud_tick_16x_wire ),
    .tx             ( tx ),
    .data           ( data_in ),
    .valid          ( valid_in ),
    .busy           ( busy )
); 
*/
endmodule