`timescale 1us / 1us

module SERVO (
    input clk_100kHz,
    input rst_n,
    input [7:0] angle,
    output reg pwm
);
    localparam [10:0] max_cnt = 11'd2000;
    reg[10:0] clk_cnt = max_cnt;
    always @(posedge clk_100kHz or negedge rst_n)
        if (!rst_n) clk_cnt <= max_cnt;
        else if (clk_cnt) begin
            clk_cnt <= clk_cnt - 1'd1;
            pwm <= clk_cnt < angle;
        end else clk_cnt <= max_cnt;
endmodule
