`timescale 1 ns / 1 ns

module uart_tx_tb ();
//==================================
//           PARAMETERS
//==================================
parameter         CLK_WIDTH = 5ns;  // 100 MHz. Clock width, half period.
parameter integer TICK_DIV  = 4;    // Abstract value of divider for sim of baud tick
                                    // without depending on standard baud rates

integer           tick_counter;
time              rst_time;         // Variable of time for reset

//==================================
//      WIRE'S, REG'S and etc
//==================================
// System required registers
logic                   sys_clk_reg;
logic                   sys_rst_reg;

logic                   baud_tick_reg;

logic   [9:0]           rx_reg_for_tx;
logic   [7:0]           tx_data_reg;

logic                   valid_wire;
logic                   busy_wire;

//==================================
//          SYSTEM CLOCK
//==================================
initial
begin
    sys_clk_reg = 0;

    forever
    begin
        #CLK_WIDTH sys_clk_reg = ~sys_clk_reg;
    end
end

//==================================
//          BAUD TICK
//==================================
always @(posedge sys_clk_reg)
begin
    if (sys_rst_reg)
    begin
        tick_counter  = 0;
        baud_tick_reg = 0;
    end
    else
    begin
        baud_tick_reg = 0;

        if (tick_counter == TICK_DIV - 1)
        begin
            tick_counter  = 0;
            baud_tick_reg = 1;
        end
        else
            tick_counter = tick_counter + 1;
    end
end

//==================================
//      Main block of testbench
//==================================
initial
begin
    $timeformat(-9, 0, " ns", 0);
    $display("---------------------------------------------");
    $display("%t [TB INFO]  STARTING TEST FOR UART_RX", $realtime);
    $display("---------------------------------------------");
    $display("");

    valid_wire  <= 0;
    tx_data_reg <= 8'h55;

    system_reset();

    @(posedge sys_clk_reg);
    valid_wire  <= 1;
    @(posedge sys_clk_reg);
    valid_wire  <= 0;

    #5ns
    $display("-------------------------------------------");
    $display("%t [TB INFO]  ALL TESTS COMPLETED", $realtime);
    $display("-------------------------------------------");
    $finish;
end

//==================================
//          INSTATIATIONS
//==================================
uart_tx dut (
    .resetn     ( ~sys_rst_reg ),
    .clk        ( sys_clk_reg ),
    .baud_tick  ( baud_tick_reg ),
    .tx         ( rx_reg_for_tx[9] ),
    .data       ( tx_data_reg ),
    .valid      ( valid_wire ),
    .busy       ( busy_wire )
);

//==================================
//         TESTBENCH TASKS
//==================================
task system_reset;
begin
    sys_rst_reg = 1;
    $display("--------------------------------");
    $display("%t [TB INFO]  RESET ASSERTED!", $realtime);
    $display("--------------------------------");

    // Set random time in range
    rst_time = $urandom_range(10ns, 50ns);
    
    #rst_time sys_rst_reg = 0;
    $display("---------------------------------");
    $display("%t [TB INFO]  RESET DEASSERTED!", $realtime);
    $display("---------------------------------");
    $display("");
end
endtask


endmodule