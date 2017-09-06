`timescale 1us / 1us

module ULTRASONIC (
    input clk_1MHz,
    input rst_n,
    output reg trig,
    input echo,
    output reg[11:0] distance
);
    pulldown(echo);
    localparam [5:0] cnt_50us = 6'd50;
    localparam [16:0] cnt_100ms = 17'd100_000;
    reg[16:0] delay_cnt = 1'd0;
    reg[13:0] dist_cnt = 1'd0;
    reg[2:0] state = 3'd0;
    always @(posedge clk_1MHz or negedge rst_n)
        if (!rst_n) begin trig <= 1'b0; state <= 3'd0; end
        else if (delay_cnt) delay_cnt <= delay_cnt - 1'd1;
        else case (state)
        3'd0: begin trig <= 1'b1; delay_cnt <= cnt_50us; state <= 3'd1; end
        3'd1: begin trig <= 1'b0; state <= 3'd2; end
        3'd2: if (echo) begin dist_cnt <= 1'd1; state <= 3'd3; end
        3'd3: begin
            dist_cnt <= dist_cnt + 1'd1;
            if (!echo) state <= 3'd4;
            if (!dist_cnt) state <= 3'd4; // overflow
        end
        3'd4: begin distance <= dist_cnt * 170 / 1000; state <= 3'd5; end
        3'd5: begin delay_cnt <= cnt_100ms; state <= 3'd0; end
        default: state <= 3'd0;
        endcase
endmodule
