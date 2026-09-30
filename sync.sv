module sync #(
    parameter ff_num = 2    // Number of FF's for sync
)(
    clk,
    async_in,
    sync_out
);
input           clk;        // System clock input
input           async_in;   // Input port for async sginal
output          sync_out;   // Output port with sync signal

//==================================
//      WIRE'S, REG'S and etc
//==================================
reg [ff_num - 1:0]  ff;

//==================================
//          ASSIGNMENTS
//==================================
assign sync_out = ff[ff_num - 1];

//==================================
//             LOGIC
//==================================
always @(posedge clk)
begin
    ff[0] <= async_in;

    for(int i = 1; i < ff_num; i++)
        ff[i] <= ff[i - 1];
end
endmodule