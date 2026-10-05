module uart_tx (
  resetn,
  clk,
  baud_tick,
  tx,
  data,
  valid,
  busy
);
input       resetn;
input       clk;
input       baud_tick;
output      tx;
input [7:0] data;
input       valid;
output      busy;

//==================================
//      WIRE'S, REG'S and etc
//==================================
reg [9:0]   shift_reg;
reg [3:0]   sample_counter;  // Sampling baud_rate x 16
reg [3:0]   bit_counter;

reg         busy_reg;
wire        en_shft;
wire       load;
  
typedef enum reg [1:0] {
    IDLE,
    SHIFT
} state_t;

state_t fsm_state;

//==================================
//          ASSIGNMENTS
//==================================  
assign busy = busy_reg;
assign en_shft = (fsm_state == SHIFT) && (sample_counter == 4'b1111);
assign load = (fsm_state == IDLE) && (valid == 1'b1);
assign tx = shift_reg[0];

//==================================
//             LOGIC
//==================================
// FSM
always @ (negedge resetn or posedge clk)
begin
    if(!resetn)
    begin
        fsm_state      <= IDLE;
        sample_counter <= 0;
        bit_counter    <= 0;
        busy_reg       <= 0;
    end
    else
    begin
        case (fsm_state)
        begin
            IDLE: begin
                sample_counter <= 0;
                bit_counter    <= 0;
                busy_reg       <= 0;
              
                if (valid)
                begin
                  busy_reg  <= 1'b1;
                  fsm_state <= SHIFT;
                end
            end
            SHIFT: begin
                if (baud_tick)
                begin
                    if (sample_counter == 4'b1111)
                    begin
                        sample_counter <= 0;

                        if (bit_counter == 4'b1001)
                        begin
                            bit_counter <= 0;
                            busy_reg    <= 1'b0;
                            fsm_state   <= IDLE;
                        end
                        else 
                        begin
                            bit_counter <= bit_counter + 1'b1;
                        end
                    end
                    else 
                    begin
                        sample_counter <= sample_counter + 1'b1;
                    end
                end
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
        shift_reg <= '1;
    else if (load)
        shift_reg[9:0] <= {1'b1, data, 1'b0};
    else if (en_shft && baud_tick)
        shift_reg <= {1'b1, shift_reg[9:1]};   // Shift from right
end
endmodule