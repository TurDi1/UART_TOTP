`timescale 1 ns / 1 ns

module uart_rx_tb ();
//==================================
//           PARAMETERS
//==================================
parameter         CLK_WIDTH = 10ns;  // 50 MHz. Clock width, half period.
parameter integer TICK_DIV  = 4;     // Abstract value of divider for sim of baud tick
                                     // without depending on standard baud rates

integer           tick_counter;
time              rst_time;          // Variable of time for reset
logic             success;           // Success simulation variable

//==================================
//      WIRE'S, REG'S and etc
//==================================
// System required registers
logic                   sys_clk_reg;
logic                   sys_rst_reg;

logic                   baud_tick_reg;
logic   [9:0]           tx_reg_for_rx;
logic   [7:0]           rx_data_reg;
logic                   valid_wire;

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
always @(negedge sys_clk_reg)
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
    tx_reg_for_rx = '1; // IDLE value

    system_reset();
    
end

//==================================
//          INSTATIATIONS
//==================================
uart_rx dut (
    .resetn     ( ~sys_rst_reg ),
    .clk        ( sys_clk_reg ),
    .baud_tick  ( baud_tick_reg ),
    .rx         ( tx_reg_for_rx[0] ),
    .data       ( rx_data_reg ),
    .valid      ( valid_wire )
);

//==================================
//         TESTBENCH TASKS
//==================================
task system_reset;
begin
    sys_rst_reg = 1;
    $display("----------------------------");
    $display("[TB INFO]  RESET SETTED!");
    $display("TIME:  %t", $realtime);
    $display("----------------------------");

    // Set random time in range between 20-40 ns
    rst_time = $urandom_range(10ns, 50ns);
    
    #rst_time sys_rst_reg = 0;
    $display("----------------------------");
    $display("[TB INFO]  RESET RELEASED!");
    $display("TIME:  %t", $realtime);
    $display("----------------------------");
    $display("");
end
endtask

task normal_send_data_to_rx;
input [7:0] tx_data;
begin
    // Load tx reg with stop, data, start bits
    tx_reg_for_rx = {1'b1, tx_data, 1'b0};

    // NOT COMPLETED TASK...
    // Here will be for loop logic that every 16 ticks shift right data in tx_reg_for_rx register
end
endtask
endmodule 