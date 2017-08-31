`timescale 1us / 1us

module MOTOR (
    input clk_100kHz,
    input rst_n,
    input [1:0] direction,
    output reg[1:0] en,
    output reg pwm
);
    localparam [9:0] max_cnt = 10'd1000;
    reg[9:0] clk_cnt = max_cnt;
    reg[9:0] pwm_cnt = 10'd200;
    always @(posedge clk_100kHz or negedge rst_n)
        if (!rst_n) clk_cnt <= max_cnt;
        else if (clk_cnt) begin
            clk_cnt <= clk_cnt - 1'd1;
            case (direction)
            2'b11: begin en <= 2'b10; pwm <= clk_cnt < pwm_cnt; end
            2'b00: begin en <= 2'b01; pwm <= clk_cnt < pwm_cnt; end
            default: begin en <= 2'b00; pwm <= 1'b0; end
            endcase
        end else clk_cnt <= max_cnt;
endmodule