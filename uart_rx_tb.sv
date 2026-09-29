`timescale 1 ns / 1 ns

module uart_rx_tb ();
//==================================
//           PARAMETERS
//==================================
parameter         CLK_WIDTH = 5ns;  // 100 MHz. Clock width, half period.
parameter integer TICK_DIV  = 4;     // Abstract value of divider for sim of baud tick
                                     // without depending on standard baud rates

integer           tick_counter;
time              rst_time;          // Variable of time for reset

//==================================
//      WIRE'S, REG'S and etc
//==================================
// System required registers
logic                   sys_clk_reg;
logic                   sys_rst_reg;

logic                   baud_tick_reg;
logic   [9:0]           tx_reg_for_rx;
logic   [7:0]           rx_data_wire;
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
    $timeformat(-9, 0, " ns", 0);
    $display("---------------------------------------------");
    $display("%t [TB INFO]  STARTING TEST FOR UART_RX", $realtime);
    $display("---------------------------------------------");
    $display("");

    tx_reg_for_rx = '1; // IDLE value

    system_reset();
    pattern_check();
    false_start();
    stop_test(8'h37);
    
    #5ns
    $display("-------------------------------------------");
    $display("%t [TB INFO]  ALL TESTS COMPLETED", $realtime);
    $display("-------------------------------------------");
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
    .data       ( rx_data_wire ),
    .valid      ( valid_wire )
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


task normal_send_data_to_rx;
input [7:0] tx_data;
begin
    // Load tx reg with stop, data, start bits
    tx_reg_for_rx = {1'b1, tx_data, 1'b0};

    $display("%t [TB INFO]  SEND DATA BYTE 0x%h TO UART_RX", $realtime, tx_data);

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

    $display("%t [TB INFO]  ==== PATTERN CHECK STARTED ====", $realtime);
    $display("");
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

    for(int i = 0; i < $size(pattern_bytes); i++)
    begin
        fork : send_n_chk
        begin
            fork
                // Sending data to receiver
                begin
                    normal_send_data_to_rx(pattern_bytes[i]);
                end
                
                // Check received data
                begin
                    wait(valid_wire == 1'b1);
                    if(rx_data_wire == pattern_bytes[i])
                    begin
                        $display("------------------------------------------------------------");
                        $display("%t [TB PASS]  TX=0x%h  RX=0x%h", $realtime, pattern_bytes[i], rx_data_wire);
                        $display("------------------------------------------------------------");
                    end
                    else
                    begin
                        $display("------------------------------------------------------------");
                        $display("%t [TB ERROR]  Sent & received bytes are not equal!", $realtime);
                        $display("%t [TB INFO]  received byte - 0x%h", $realtime, rx_data_wire);
                        $display("%t [TB INFO]  sent byte   - 0x%h", $realtime, pattern_bytes[i]);
                        $display("------------------------------------------------------------");
                        $fatal;
                    end
                end
            join
        end

        begin
            repeat (500)
                @(posedge baud_tick_reg);

            $display("----------------------------------------------------------");
            $display("%t [TB ERROR] TIMEOUT: UART_RX ARE STUCK", $realtime);
            $display("----------------------------------------------------------");
            $fatal;
        end
        join_any
        disable send_n_chk;
    end
    $display("%t [TB INFO]  ==== PATTERN CHECK COMPLETED ====", $realtime);
    $display("");
end
endtask


task false_start;
begin
    $display("%t [TB INFO]  ==== FALSE START SUBTEST CHECK STARTED ====", $realtime);
    fork : wait_start
        begin
            fork
                begin
                    if (dut.fsm_state == 2'b00 && valid_wire == 1'b0 && dut.rx == 1'b1)  // Check UART_RX before assign RX to LOW
                    begin
                        tx_reg_for_rx = 10'b1111111110; // Load tx reg with only start bit
                        repeat (3) // Wait 3x ticks
                        begin
                            @(posedge baud_tick_reg);
                        end
                    end
                    else
                    begin
                        $display("%t [TB ERROR]  UART_RX ARE: 1) NOT IN IDLE STATE,", $realtime);
                        $display("%t [TB ERROR]  2) NOT VALID IS LOW", $realtime);
                        $display("%t [TB ERROR]  3) NOT RX PORT IS HIGH", $realtime);
                        $fatal;
                    end
                end

                begin   // Waiting change state from idle to start
                    wait(dut.fsm_state == 2'b01);
                    $display("%t [TB INFO] CAPTURED CHANGE OF STATE TO START AFTER FALSE RX PORT TO LOW", $realtime);
                end
            join
        end

        begin   // Check restricted states
            wait(dut.fsm_state == 2'b10 || dut.fsm_state == 2'b11);
            $display("%t [TB ERROR] RESTRICTED STATE DATA OR STOP OF FSM IN SUBTEST!", $realtime);
            $fatal;
        end

        begin   // TIMEOUT
            repeat (500)
                @(posedge baud_tick_reg);

            $display("--------------------------------------------------------------------");
            $display("%t [TB ERROR] TIMEOUT: UART_RX ARE NOT CHANGE TO START STATE", $realtime);
            $display("--------------------------------------------------------------------");
            $fatal;
        end
    join_any
    disable wait_start;


    $display("%t [TB INFO] CHANGE RX PORT TO HIGH BEFORE START BIT SAMPLING ARE END", $realtime);
    tx_reg_for_rx = 10'b1111111111;


    fork : wait_chng
        begin   // FSM checker of expected IDLE
            wait(dut.fsm_state == 2'b00 && valid_wire == 1'b0);
            $display("%t [TB INFO] CAPTURED CHANGE OF STATE TO IDLE", $realtime);
        end

        begin   // Check restricted states
            wait(dut.fsm_state == 2'b10 || dut.fsm_state == 2'b11);
            $display("%t [TB ERROR] RESTRICTED STATE DATA OR STOP OF FSM IN SUBTEST!", $realtime);
            $fatal;
        end

        begin   // Valid checker in proccess
            wait(valid_wire == 1'b1);
            $display("%t [TB ERROR]  CAPTURED VALID FLAG!", $realtime);
            $fatal;
        end

        begin   // TIMEOUT
            repeat (500)
                @(posedge baud_tick_reg);

            $display("-------------------------------------------------------------");
            $display("%t [TB ERROR] TIMEOUT: UART_RX ARE STUCK IN START STATE", $realtime);
            $display("-------------------------------------------------------------");
            $fatal;
        end
    join_any
    disable wait_chng;
    $display("%t [TB INFO]  ==== FALSE START SUBTEST CHECK COMPLETED ====", $realtime);
    $display("");
end
endtask


task stop_test;
input [7:0] tx_data;
begin
    $display("%t [TB INFO]  ==== BROKEN STOP SUBTEST STARTED ====", $realtime);

    if (dut.fsm_state != 2'b00 || valid_wire != 1'b0 || dut.rx != 1'b1)
    begin
        $display("%t [TB ERROR]  UART_RX ARE: 1) NOT IN IDLE STATE,", $realtime);
        $display("%t [TB ERROR]  2) NOT VALID IS LOW", $realtime);
        $display("%t [TB ERROR]  3) NOT RX PORT IS HIGH", $realtime);
        $fatal;
    end

    fork : broken_stop_check
        begin
            fork
                begin
                    // Load broken STOP, DATA, START
                    tx_reg_for_rx = {1'b0, tx_data, 1'b0};

                    $display("%t [TB INFO] SEND DATA BYTE 0x%h WITH BROKEN STOP", $realtime, tx_data);
                    repeat (10)
                    begin
                        repeat (16)
                            @(posedge baud_tick_reg);

                        tx_reg_for_rx = {1'b1, tx_reg_for_rx[9:1]};
                    end
                end

                begin
                    // Expected sequence
                    wait(dut.fsm_state == 2'b01); // START
                    $display("%t [TB INFO] CAPTURED START STATE", $realtime);

                    wait(dut.fsm_state == 2'b10); // DATA
                    $display("%t [TB INFO] CAPTURED DATA STATE", $realtime);

                    wait(dut.fsm_state == 2'b11); // STOP
                    $display("%t [TB INFO] CAPTURED STOP STATE", $realtime);

                    wait(dut.fsm_state == 2'b00 && valid_wire == 1'b0); // IDLE
                    $display("%t [TB PASS] BROKEN STOP REJECTED, VALID=0",
                             $realtime);
                end
            join
        end

        begin // Valid checker
            wait(valid_wire == 1'b1);
            $display("------------------------------------------------------------");
            $display("%t [TB ERROR] VALID ASSERTED WITH BROKEN STOP BIT!", $realtime);
            $display("------------------------------------------------------------");
            $fatal;
        end

        begin // Timeout
            repeat (500)
                @(posedge baud_tick_reg);

            $display("------------------------------------------------------------");
            $display("%t [TB ERROR] TIMEOUT IN BROKEN STOP TEST", $realtime);
            $display("------------------------------------------------------------");
            $fatal;
        end
    join_any
    disable broken_stop_check;

    $display("%t [TB INFO]  ==== BROKEN STOP SUBTEST COMPLETED ====", $realtime);
    $display("");
end
endtask
endmodule