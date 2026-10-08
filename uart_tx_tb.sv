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
logic             sys_clk_reg;
logic             sys_rst_reg;

logic             baud_tick_reg;

logic   [9:0]     rx_reg_for_tx;
logic   [7:0]     tx_data_reg;

logic             valid_wire;
logic             busy_wire;

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
        tick_counter  <= 0;
        baud_tick_reg <= 0;
    end
    else
    begin
        baud_tick_reg <= 0;

        if (tick_counter == TICK_DIV - 1)
        begin
            tick_counter  <= 0;
            baud_tick_reg <= 1;
        end
        else
            tick_counter <= tick_counter + 1;
    end
end

//==================================
//      Main block of testbench
//==================================
initial
begin
    $timeformat(-9, 0, " ns", 0);
    $display("---------------------------------------------");
    $display("%t [TB INFO]  STARTING TEST FOR UART_TX", $realtime);
    $display("---------------------------------------------");
    $display("");

    pattern_check();

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

task pattern_check;
begin
    logic [8:0] [7:0] pattern_bytes;

    // Check useful pattern of bytes in HEX: 00 FF 55 AA 01 80 0F F0 37
    pattern_bytes[0] = 8'h00;
    pattern_bytes[1] = 8'hFF;
    pattern_bytes[2] = 8'h55;
    pattern_bytes[3] = 8'hAA;
    pattern_bytes[4] = 8'h01;
    pattern_bytes[5] = 8'h80;
    pattern_bytes[6] = 8'h0F;
    pattern_bytes[7] = 8'hF0;
    pattern_bytes[8] = 8'h37;

    tx_data_reg = 0;
    valid_wire = 0;

    // After reset check
    system_reset();
    @(posedge sys_clk_reg);

    if ((rx_reg_for_tx[9] != 1'b1) || (busy_wire != 0))
    begin
        $display("%t [TB ERROR]  TX PORT ARE NOT IN HIGH AND BUSY PORT ARE NOT IN LOW AFTER RESET!", $realtime);
        $fatal;
    end
    else
    begin
        $display("%t [TB INFO]  TX AND BUSY PORTS ARE IN RIGHT STATE AFTER RESET", $realtime);
    end

    // Pattern/frame test
    $display("%t [TB INFO]  ==== PATTERN/FRAME TEST STARTED ====", $realtime);
    $display("");

    for(int i = 0; i < $size(pattern_bytes); i++)
    begin
        $display("%t [TB INFO]  ==== SEND [%h] BYTE OF PATTERN BYTES ====", $realtime, pattern_bytes[i]);
        normal_send_data(pattern_bytes[i]);
    end

    // Not completed
end    
endtask

task normal_send_data;
input [7:0] tx_data;
begin
    // Send data to uart_tx
    @(posedge sys_clk_reg);
    tx_data_reg = tx_data;
    valid_wire  = 1;

    @(posedge sys_clk_reg);
    valid_wire  = 0;

    @(posedge sys_clk_reg);
    
    // Start checking bits
    repeat(7)
        @(posedge baud_tick_reg);
    
    if(rx_reg_for_tx[9] == 1'b0)    // Check START bit
        $display("%t [TB INFO]  START BIT OF FRAME HAVE CORRECT VALUE", $realtime);  
    else
    begin
        $display("%t [TB INFO]  START BIT OF FRAME HAVE INCORRECT VALUE", $realtime);
        $fatal;
    end

    for(int i = 0; i < 8; i++)  // Check DATA bits
    begin
        repeat(16)
            @(posedge baud_tick_reg);
        
        if (rx_reg_for_tx[9] == tx_data[i])
            $display("%t [TB INFO]  d%d BIT OF FRAME HAVE CORRECT VALUE", $realtime, i);
        else
        begin
            $display("%t [TB INFO]  d%d BIT OF FRAME HAVE INCORRECT VALUE", $realtime, i);
            $display("%t [TB INFO]  EXPECTED - %b | RECEIVED - %b", $realtime, tx_data[i], rx_reg_for_tx[i]);
            $fatal;
        end
    end

end
endtask
endmodule