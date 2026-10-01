`timescale 1 ns / 1 ns

module baud_tick_gen_tb ();
//==================================
//           PARAMETERS
//==================================
parameter         CLK_WIDTH = 5ns;  // 100 MHz. Clock width, half period.
time              rst_time;         // Variable of time for reset

int               N;

//==================================
//      WIRE'S, REG'S and etc
//==================================
typedef struct {
    int min_interval;
    int max_interval;
} tick_interval_t;

tick_interval_t expected_intervals [9] = '{
    '{1302, 1303},      // 4800
    '{ 651,  652},      // 9600
    '{ 325,  326},      // 19200
    '{ 162,  163},      // 38400
    '{ 108,  109},      // 57600
    '{  54,   55},      // 115200
    '{  27,   28},      // 230400
    '{  13,   14},      // 460800
    '{   6,    7}       // 921600
};

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

    N = $urandom_range(5000, 10000);
    baud_rate_sel = 4'd5;

    system_reset();
    baud_tick_chk();
    
    #5ns
    $display("");
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
    @(posedge sys_clk_reg);

    // After reset check
    if (baud_tick_reg)
    begin
        $display("%t [TB ERROR]  BAUD TICK GENERATOR HAVE HIGH ON BAUD TICK PORT AFTER RESET!", $realtime);
        $fatal;
    end
    else
    begin
        $display("%t [TB INFO]  GENERATOR HAVE LOW ON BAUD TICK PORT AFTER RESET - CORRECT VALUE", $realtime);
    end

    // Check baud tick width should be one sys clk cycle
    @(posedge baud_tick_reg);

    @(negedge sys_clk_reg);
    if (!baud_tick_reg)
    begin
        $display("%t [TB ERROR]  BAUD TICK PORT AFTER HALF PERIOD SYS CLOCK IS LOW!", $realtime);
        $fatal;        
    end

    @(negedge sys_clk_reg);
    if (baud_tick_reg)
    begin
        $display("%t [TB ERROR]  BAUD TICK PORT AFTER PERIOD SYS CLOCK IS HIGH!", $realtime);
        $fatal;        
    end
    else
    begin
        $display("%t [TB INFO]  BAUD TICK PORT AFTER PERIOD SYS CLOCK IS LOW - CORRECT WIDTH", $realtime);
    end

    // Check interval between ticks for current 16x baud rate
    check_tick_interval();
end
endtask

task check_tick_interval;
int lower_bound;
int upper_bound;
int interval;
begin
    // Assign values in variables
    lower_bound = expected_intervals[baud_rate_sel].min_interval;
    upper_bound = expected_intervals[baud_rate_sel].max_interval;

    interval = 0;
    // First capture of baud tick
    @(posedge baud_tick_reg);

    // Waiting negedge of baud tick
    @(negedge baud_tick_reg);

    // Capturing sys clk posedges btw ticks
    forever
    begin
        @(negedge sys_clk_reg);
        interval++;

        if (baud_tick_reg)
            break;
    end

    // Checking of interval for out-of-range
    if ((interval < lower_bound) || (interval > upper_bound))
    begin
        $display("%t [TB ERROR]  INVALID TICK INTERVAL: %0d", $realtime, interval);
        $display("%t [TB INFO]  EXPECTED: %0d..%0d", $realtime, lower_bound, upper_bound);
        $fatal;
    end    
end
endtask
endmodule