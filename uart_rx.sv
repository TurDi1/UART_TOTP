module uart_rx (
    resetn,
    clk,
    baud_tick,
    rx,
    data,
    valid
);
input               resetn;    // System reset input (active LOW)
input               clk;       // System clock input
input               baud_tick;
input               rx;        // Serial data input
output [7:0]        data;      // Received data bus
output              valid;     // Valid data flag

//==================================
//      WIRE'S, REG'S and etc
//==================================
reg [7:0]           shift_reg;       // Shift register for storing data bits
reg                 valid_reg;

reg [3:0]           sample_counter;
reg [2:0]           bit_counter;

wire                en_shft;

typedef enum reg [1:0] {
    IDLE,
    START,
    DATA,
    STOP 
} state_t;

state_t fsm_state;

//==================================
//          ASSIGNMENTS
//==================================
assign data    = shift_reg;
assign valid   = valid_reg;
assign en_shft = (fsm_state == DATA) && (sample_counter == 4'b1111);

//==================================
//             LOGIC
//==================================
// UART protocol FSM
always @ (negedge resetn or posedge clk)
begin
    if(!resetn)
    begin
        fsm_state      <= IDLE;
        valid_reg      <= 0;
        sample_counter <= 0;
        bit_counter    <= 0;        
    end
    else
    begin
        case (fsm_state)
            IDLE: begin
                valid_reg  <= 0;
                sample_counter <= 0;
                //en_shft        <= 0;
                bit_counter    <= 0;

                if (rx == 0)
                    fsm_state  <= START;
            end
            START: begin    // Checking that it was not noise
                if (baud_tick)
                begin
                    if (sample_counter == 4'b0111)
                    begin
                        sample_counter <= 0;

                        if (rx == 0)
                            fsm_state <= DATA;
                        else
                            fsm_state <= IDLE;
                    end
                    else
                        sample_counter <= sample_counter + 1;
                end
            end
            DATA: begin
                if (baud_tick)
                begin
                    if (sample_counter == 4'd15) begin
                        sample_counter <= 0;

                        if (bit_counter == 3'd7) begin
                            bit_counter <= 0;
                            fsm_state   <= STOP;
                        end
                        else begin
                            bit_counter <= bit_counter + 1'b1;
                        end
                    end
                    else begin
                        sample_counter <= sample_counter + 1'b1;
                    end
                end
            end
            STOP: begin
                if (baud_tick)
                begin                
                    if (sample_counter == 4'b1111)
                    begin
                        if (rx == 1)
                            valid_reg <= 1;
                        
                        sample_counter <= 0;
                        fsm_state <= IDLE;                        
                    end
                    else
                        sample_counter <= sample_counter + 1;
                end
            end
            default: fsm_state <= IDLE;
        endcase
    end
end

// Shift register logic
always @(negedge resetn or posedge clk)
begin
    if (!resetn)
        shift_reg <= 0;
    else if (en_shft && baud_tick)
        shift_reg <= {rx, shift_reg[7:1]};   // Shift from right
end
endmodule