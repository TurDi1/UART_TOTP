`timescale 1 ns / 1 ns

module riscv_tb_beq ();
//==================================
//           PARAMETERS
//==================================
parameter CLK_WIDTH = 10ns;  // 50 MHz. Clock width, half period.

logic rst_time;              // Variable of time for reset
logic success;               // Success simulation variable

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
//      Main block of testbench
//==================================
initial
begin
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
    rst_time = $urandom_range(20ns, 40ns);
    
    #rst_time sys_rst_reg = 0;
    $display("----------------------------");
    $display("[TB INFO]  RESET RELEASED!");
    $display("TIME:  %t", $realtime);
    $display("----------------------------");
    $display("");
end
endtask
//
endmodule 