module sync #(
    parameter ff_num = 2
)(
    clk,
    async_in,
    sync_out
);
input           clk;
input           async_in;
output          sync_out;

reg [ff_num - 1:0]  ff;

assign sync_out = ff[ff_num - 1];

always @(posedge clk)
begin
    ff[0] <= async_in;

    for(int i = 1; i < ff_num; i++)
        ff[i] <= ff[i - 1];
end
endmodule