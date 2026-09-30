`timescale 1 ns / 1 ns

module baud_tick_gen_tb ();
//==================================
//           PARAMETERS
//==================================
parameter         CLK_WIDTH = 5ns;  // 100 MHz. Clock width, half period.

time              rst_time;         // Variable of time for reset

//==================================
//      WIRE'S, REG'S and etc
//==================================
// System required registers
logic                   sys_clk_reg;
logic                   sys_rst_reg;

logic   [3:0]           baud_rate_sel;
logic                   baud_tick_reg;

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
    $timeformat(-9, 0, " ns", 0);
    $display("-----------------------------------------------------");
    $display("%t [TB INFO]  STARTING TEST OF BAUD TICK GENERATOR", $realtime);
    $display("-----------------------------------------------------");
    $display("");

    baud_rate_sel = 4'd5;
    system_reset();

    
    #5ns
    $display("-------------------------------------------");
    $display("%t [TB INFO]  TEST COMPLETED", $realtime);
    $display("-------------------------------------------");
    $finish;
end

//==================================
//          INSTATIATIONS
//==================================
baud_tick_gen dut (
    .resetn         ( ~sys_rst_reg ),
    .clk            ( sys_clk_reg ),
    .baud_rate_sel  ( baud_rate_sel ),
    .baud_tick_16x  ( baud_tick_reg )
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

task baud_tick_chk;
begin
    if (baud_tick_reg)
    begin
        
    end
    // Not completed task
end
endtask
endmodule