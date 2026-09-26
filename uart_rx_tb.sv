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
    tx_reg_for_rx = '1; // IDLE value

    system_reset();
    pattern_check();
    
    #10ns
    $finish;
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

    repeat (10) // Starting shift loop of all ten bits
    begin
        repeat (16) // Wait 16x ticks
        begin
            @(posedge baud_tick_reg);
        end

        tx_reg_for_rx = {1'b1, tx_reg_for_rx[9:1]};
    end
end
endtask

task pattern_check;
begin
    logic [8:0] [7:0] pattern_bytes;

    // Check useful pattern of bytesin HEX: 00 FF 55 AA 01 80 0F F0 37
    pattern_bytes[0] = 8'h00;
    pattern_bytes[1] = 8'hFF;
    pattern_bytes[2] = 8'h55;
    pattern_bytes[3] = 8'hAA;
    pattern_bytes[4] = 8'h01;
    pattern_bytes[5] = 8'h80;
    pattern_bytes[6] = 8'h0F;
    pattern_bytes[7] = 8'hF0;
    pattern_bytes[8] = 8'h37;
      
    // Not completed task
    for(int i = 0; i < $size(pattern_bytes); i++)
    begin
        normal_send_data_to_rx(pattern_bytes[i]);
    end
end
endtask
endmodule