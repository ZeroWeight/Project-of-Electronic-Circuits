`timescale 1us / 1us

module CLK_GEN #(
    parameter SYS_CLK_FREQ = 100_000_000,
    parameter FREQ = 100_000
)(
    input sys_clk,
    input rst_n,
    output clk
);
    localparam max_cnt = SYS_CLK_FREQ / FREQ - 1;
    localparam half_cnt = max_cnt >> 1;
    reg[31:0] clk_cnt = max_cnt;
    reg[0:2] clk_reg = 3'b0;
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) clk_cnt <= max_cnt;
        else if (clk_cnt) clk_cnt <= clk_cnt - 1'b1;
        else clk_cnt <= max_cnt;
    always @(posedge sys_clk or negedge rst_n)
        if (!rst_n) clk_reg <= 3'b0;
        else clk_reg <= {clk_cnt > half_cnt, clk_reg[0:1]};
    assign clk = clk_reg[1] & ~clk_reg[2]; // posedge
endmodule
